path "developers/*"
{
  capabilities = ["list"]
}

path "auth/token/create" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "aws-developer-path/creds/aws-developer-role" {
  capabilities = ["read"]
}

path "developers/data/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}