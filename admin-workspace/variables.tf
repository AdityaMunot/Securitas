variable "VAULT_ADDR" { default = "" }
variable "VAULT_TOKEN" { default = ""}
variable "userpass_default_lease_ttl" { default = "28800s"}
variable "userpass_max_lease_ttl" { default = "28800s"}
variable "aws_default_lease_ttl_seconds" { default = "120"}
variable "aws_max_lease_ttl_seconds" { default = "240"}
variable "aws_profile" { default = "default" }
variable "name" { default = "aws-developer" }