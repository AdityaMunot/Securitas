# Vault Cluster Deployment

This folder has  [Vault](https://www.vaultproject.io/) cluster on [AWS](https://aws.amazon.com/) using [Terraform](https://www.terraform.io/). Vault is an open source tool for managing secrets. By default, this Module uses [Consul](https://www.consul.io/) as a [storage backend](https://www.vaultproject.io/docs/configuration/storage/index.html).

## Inputs

| Name                    | Description                                                  | Type          | Required |
| ----------------------- | ------------------------------------------------------------ | ------------- | -------- |
| create_dns_entry        | creates a Route 53 DNS A record for the ELB                  | `bool`        | No       |
| hosted_zone_domain_name | domain name of the Route 53 Hosted Zone                      | `string`      | No       |
| vault_domain_name       | domain name to use in the DNS A record for the Vault ELB     | `string`      | No       |
| ami_id                  | The ID of the AMI to run in the cluster                      | `string`      | No       |
| ssh_key_name            | The name of an EC2 Key Pair that can be used to SSH to the EC2 Instances in this cluster. Set to an empty string to not associate a Key Pair. | `string`      | No       |
| subnet_tags             | Tags used to find subnets for vault and consul servers       | `map(string)` | No       |
| vpc_tags                | Tags used to find a vpc for building resources               | `map(string)` | No       |
| use_default_vpc         | Whether to use the default VPC or use vpc_tags to find your vpc | `bool`        | No       |
| vault_cluster_name      | What to name the Vault server cluster and all of its associated resources | `string`      | No       |
| consul_cluster_name     | What to name the Consul server cluster and all of its associated resources | `string`      | No       |
| vault_cluster_size      | The number of Vault server nodes to deploy                   | `number`      | No       |
| consul_cluster_size     | The number of Consul server nodes to deploy                  | `number`      | No       |
| vault_instance_type     | The type of EC2 Instance to run in the Vault ASG             | `string`      | No       |
| consul_instance_type    | The type of EC2 Instance to run in the Consul ASG            | `string`      | No       |
| consul_cluster_tag_key  | The tag the Consul EC2 Instances will look for to automatically discover each other and form a cluster. | `string`      | No       |



## Usage



If using Terraform Open Source, execute the following commands:

Request:

```bash
>terraform init
>terraform plan
>terraform apply
```

Result:

![cluster_deployed](../asset/cluster_deployed.PNG)

Request:

```bash
>bash vault-cluster-helper.sh
```

Result:

![bash_helper](../asset/bash_helper.PNG)

Request:

```bash
>vault operator init
```

Result:

![vault_operator_init](../asset/vault_operator_init.PNG)

Request:

```
vault operator unseal
```

Result:

![unseal_vault](../asset/unseal_vault.PNG)

## Result:

![vault_consul_cluster](../asset/vault_consul_cluster.PNG)

## Author

Managed by [Aditya Munot](https://github.com/AdityaMunot)