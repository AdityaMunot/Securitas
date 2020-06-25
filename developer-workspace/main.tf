terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "vault" {
    address         = var.vault_address
    token           = var.developer_token
    skip_tls_verify = "true"
}

data "vault_aws_access_credentials" "creds" {
  backend = var.aws_backend
  role    = var.aws_role
}

provider "aws" {
  access_key = data.vault_aws_access_credentials.creds.access_key
  secret_key = data.vault_aws_access_credentials.creds.secret_key
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Create AWS EC2 Instance
resource "aws_instance" "main" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name  =  "${var.name}"
    TTL   =  "${var.ttl}"
    owner =  "${var.name}-guide"
  }
}