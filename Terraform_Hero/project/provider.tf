# ==============================| Configure the AWS Provider |==============================
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.53.0"
    }
  }
}
