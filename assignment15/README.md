# Serverless Workflow — AWS Step Functions + Lambda (Terraform)

A two-step serverless workflow orchestrated by AWS Step Functions, with
CloudWatch/SNS monitoring on top:

```
Input --> [ProcessData Lambda] --> [StoreData Lambda] --> DynamoDB
                                          |
                                          v
                              CloudWatch metric (ItemsStored)
                                          |
                                          v
                              CloudWatch Alarm --> SNS Topic --> Email
```

- **ProcessData** (`lambda/process/index.py`): receives raw input (`id`, `value`),
  transforms it (uppercases the value, adds a timestamp), and passes the result on.
- **StoreData** (`lambda/store/index.py`): receives the processed data, writes
  it as an item into a DynamoDB table, and publishes a custom CloudWatch metric
  (`ServerlessWorkflow/ItemsStored`) each time an item is stored.
- Both steps have `Retry`/`Catch` blocks in the state machine definition, so
  transient Lambda failures are retried and unhandled errors route to a `Fail` state.
- A **CloudWatch Alarm** watches the `ItemsStored` metric and fires when the sum
  is >= 1 within a 1-minute window, notifying an **SNS topic** with an **email
  subscription**.

## File layout

```
.
├── versions.tf              # Terraform + provider requirements
├── variables.tf             # Input variables (region, project name)
├── iam.tf                   # IAM roles/policies for Lambda + Step Functions
├── lambda.tf                # Lambda function resources (zipped from lambda/)
├── dynamodb.tf               # DynamoDB table for storing processed data
├── state_machine.tf         # Step Functions state machine resource
├── state_machine.asl.json   # Amazon States Language definition (templated)
├── sns.tf                    # SNS topic + email subscription + topic policy
├── cloudwatch.tf             # CloudWatch alarm on the ItemsStored metric
├── outputs.tf                # Useful output values after apply
└── lambda/
    ├── process/index.py     # Step 1 Lambda source
    └── store/index.py       # Step 2 Lambda source
```

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured with credentials that have permission to create
  Lambda, IAM, Step Functions, and DynamoDB resources
  (`aws configure` or environment variables)

## Deploy

You must supply an email address for alarm notifications, either via a
`terraform.tfvars` file or the `-var` flag:

```bash
terraform init
terraform plan  -var="alert_email=you@example.com"
terraform apply -var="alert_email=you@example.com"
```

Terraform will zip the two Lambda source folders automatically via the
`archive_file` data source — no manual packaging needed.

**Important:** After `apply`, AWS SNS sends a confirmation email to the
address you provided. You must click the confirmation link in that email
before the subscription becomes active and notifications can be delivered.

## Test the workflow

After `terraform apply`, start an execution using the state machine ARN
from the outputs:

```bash
aws stepfunctions start-execution \
  --state-machine-arn "$(terraform output -raw state_machine_arn)" \
  --input '{"id": "item-001", "value": "ce13-kh-cloudwatch-alarm-sns-notification-hello world"}'
```

Check the execution status:

```bash
aws stepfunctions list-executions \
  --state-machine-arn "$(terraform output -raw state_machine_arn)" \
  --max-results 1
```

Verify the item landed in DynamoDB:

```bash
aws dynamodb get-item \
  --table-name "$(terraform output -raw dynamodb_table_name)" \
  --key '{"id": {"S": "item-001"}}'
```

You can also watch the execution graph visually in the AWS Console under
**Step Functions > State machines**.

### Verify the alarm and notification

After a successful execution, the `StoreData` Lambda publishes a data point
to the `ServerlessWorkflow/ItemsStored` custom metric. Within about a minute,
the CloudWatch alarm should transition to `ALARM` state and SNS should send
an email to the address you subscribed.

Check the alarm state manually:

```bash
aws cloudwatch describe-alarms \
  --alarm-names "$(terraform output -raw cloudwatch_alarm_name)"
```

Or view it in the Console under **CloudWatch > Alarms**.

## Clean up

```bash
terraform destroy
```

## Notes for extending this

- Add more steps by adding states to `state_machine.asl.json` and wiring
  their `Next` fields, plus a matching Lambda + IAM invoke permission.
- Swap `ResultPath`/`Parameters` in the ASL if you want to pass only part
  of the payload to the next state, or merge outputs instead of overwriting.
- Add a `Choice` state after `ProcessData` if you want conditional branching
  (e.g., route to different storage based on data type).
- The alarm currently fires on *any* stored item (threshold >= 1) to
  demonstrate the notification path per the task requirements. For real
  monitoring, you'd typically raise the threshold and widen the period
  (e.g., alert only if throughput drops to zero, or spikes abnormally).
