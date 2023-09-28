variable "ami_value" {
    description = "value for the ami"
}

variable "instance_type" {
  description = "value"
  type = map(string)

  default = {
    "dev" = "t2.micro"
    "stage" = "t2.medium"
    "prod" = "t2.xlarge"
  }
}

variable "subnet_id_value" {
    description = "value for the subnet_id"
}
