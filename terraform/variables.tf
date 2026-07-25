variable "shared_config_files" {
  type    = string
  default = "C:/Users/tom/.aws/config"
}

variable "shared_credentials_files" {
  type    = string
  default = "C:/Users/tom/.aws/credentials"
}

#general variables

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "vpc_name" {
  type    = string
  default = "main-vpc"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "192.168.100.0/24"
}



locals {
  env_name = "${var.vpc_name}-${var.env}"
  
  my_ip_cidr = "${chomp(data.http.my_ip.response_body)}/32"

}