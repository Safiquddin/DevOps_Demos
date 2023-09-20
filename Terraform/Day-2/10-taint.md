Terraform Taint:
You can use the terraform taint command to mark a resource as "tainted," which indicates that Terraform should recreate that resource during the next terraform apply. Tainting a resource effectively triggers Terraform to recreate it.

Example:
terraform taint aws_instance.web_server
