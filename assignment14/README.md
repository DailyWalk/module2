# Serverless Workflow — AWS Step Functions + Lambda (Terraform)

A two-step serverless workflow orchestrated by AWS Step Functions:

```
Input --> [ProcessData Lambda] --> [StoreData Lambda] --> DynamoDB
```

- **ProcessData** (`lambda/process/index.py`): receives raw input (`id`, `value`),
  transforms it (uppercases the value, adds a timestamp), and passes the result on.
- **StoreData** (`lambda/store/index.py`): receives the processed data and writes
  it as an item into a DynamoDB table.
- Both steps have `Retry`/`Catch` blocks in the state machine definition, so
  transient Lambda failures are retried and unhandled errors route to a `Fail` state.

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

```bash
terraform init
terraform plan
terraform apply
```

Terraform will zip the two Lambda source folders automatically via the
`archive_file` data source — no manual packaging needed.

## Test the workflow

After `terraform apply`, start an execution using the state machine ARN
from the outputs:

```bash
aws stepfunctions start-execution \
  --state-machine-arn "$(terraform output -raw state_machine_arn)" \
  --input '{"id": "item-001", "value": "hello world"}'
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
