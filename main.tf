terraform {
  backend "remote" {
    organization = "orgjoaolms"

    workspaces {
      name = "tech-talk"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.66.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "joaosobrinho"
  region  = "sa-east-1"
}

data "aws_ami" "ubuntu_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu_ami.id
  instance_type = "t2.micro"

  tags = {
    Name    = "ExampleAppServerInstance"
    Projeto = "XPTO"
  }
}

output "app_server_public_ip" {
  value = aws_instance.app_server.public_ip
}

output "app_server_public_dns" {
  value = aws_instance.app_server.public_dns
}