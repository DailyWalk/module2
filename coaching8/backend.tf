terraform {
  backend "s3" {
    bucket = "sctp-tfstate-ce13" #Change to your bucket name, e.g. sctp-tfstate-jazeel
    key    = "kuohong/module2/coaching8/terraform.tfstate"#"path/to/my/key"
    region = "us-east-1"
  }
}
