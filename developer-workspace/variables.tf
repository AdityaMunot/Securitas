variable "vault_address" {
  description = "Enter the vault cluster elastic load balancer address"
  type        = string
  default     = ""
}

variable "developer_token" {
  description = "Enter Temporary token. User can generate token by login in vault with userpass"
  type        = string
  default     = ""
}

variable "aws_backend" {
    description = "Enter vault aws backend value"
    type        = string
    default     = ""
}

variable "aws_role" {
    description = "Enter vault aws role value"
    type        = string
    default     = ""
}


variable "name" {
  description = "Enter name tag value"
  type        = string
  default     = ""
}

variable "ttl" {
  description = "Enter TTL value"
  type        = string
  default     = ""
}

