terraform {
  required_version = ">= 0.12"
}

data "aws_ami" "vault_consul" {
  most_recent = true
  owners = ["self"]
  tags = {
      Name = "vault-consul-ubuntu-18"
  }
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name_prefix = var.cluster_name

  launch_configuration = aws_launch_configuration.launch_configuration.name

  availability_zones  = var.availability_zones
  vpc_zone_identifier = var.subnet_ids

  # Use a fixed-size cluster
  min_size             = var.cluster_size
  max_size             = var.cluster_size
  desired_capacity     = var.cluster_size
  termination_policies = [var.termination_policies]

  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  wait_for_capacity_timeout = var.wait_for_capacity_timeout

  enabled_metrics = var.enabled_metrics

  # Use bucket and policies names in tags for depending on them when they are there
  # And only create the cluster after S3 bucket and policies exist
  # Otherwise Vault might boot and not find the bucket or not yet have the necessary permissions
  # Not using `depends_on` because these resources might not exist
  tag {
    key                 = var.cluster_tag_key
    value               = var.cluster_name
    propagate_at_launch = true
  }

  tag {
    key                 = "using_s3_bucket_backend"
    value               = element(concat(aws_iam_role_policy.vault_s3.*.name, [""]), 0)
    propagate_at_launch = true
  }

  tag {
    key                 = "s3_bucket_id"
    value               = element(concat(aws_s3_bucket.vault_storage.*.id, [""]), 0)
    propagate_at_launch = true
  }


  # Use table policy name in tags for depending on them when they are there
  # And only create the cluster after dynamo exists
  # Otherwise Vault might boot and not find the bucket or not yet have the necessary permissions
  # Not using `depends_on` because these resources might not exist
  
  tag {
    key                 = "using_auto_unseal"
    value               = element(concat(aws_iam_role_policy.vault_auto_unseal_kms.*.name, [""]), 0)
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.cluster_extra_tags

    content {
      key                 = tag.value.key
      value               = tag.value.value
      propagate_at_launch = tag.value.propagate_at_launch
    }
  }


  # aws_launch_configuration.launch_configuration in this module sets create_before_destroy to true, which means
  # everything it depends on, including this resource, must set it as well, or you'll get cyclic dependency errors
  # when you try to do a terraform destroy.
  lifecycle {
    create_before_destroy = true
  }
}
module "vault_cluster" {
 
  source = "github.com/hashicorp/terraform-aws-vault//modules/vault-cluster?ref=v0.13.7"

  cluster_name  = var.vault_cluster_name
  cluster_size  = var.vault_cluster_size
  instance_type = var.vault_instance_type

  ami_id    = var.ami_id == null ? data.aws_ami.vault_consul.image_id : var.ami_id
  user_data = data.template_file.user_data_vault_cluster.rendered

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids

  health_check_type = "EC2"

  allowed_ssh_cidr_blocks              = ["0.0.0.0/0"]
  allowed_inbound_cidr_blocks          = ["0.0.0.0/0"]
  allowed_inbound_security_group_ids   = []
  allowed_inbound_security_group_count = 0
  ssh_key_name                         = var.ssh_key_name
}

module "consul_iam_policies_servers" {
  source = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-iam-policies?ref=v0.7.4"

  iam_role_id = module.vault_cluster.iam_role_id
}

data "template_file" "user_data_vault_cluster" {
  template = file("${path.module}/user-data/user-data-vault.sh")

  vars = {
    aws_region               = data.aws_region.current.name
    consul_cluster_tag_key   = var.consul_cluster_tag_key
    consul_cluster_tag_value = var.consul_cluster_name
  }
}

module "security_group_rules" {
  source = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-client-security-group-rules?ref=v0.7.4"

  security_group_id = module.vault_cluster.security_group_id

  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
}

module "vault_elb" {

  source = "github.com/hashicorp/terraform-aws-vault//modules/vault-elb?ref=v0.13.7"

  name = var.vault_cluster_name

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids

  vault_asg_name = module.vault_cluster.asg_name

  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]

  create_dns_entry = var.create_dns_entry

  hosted_zone_id = var.create_dns_entry ? join("", data.aws_route53_zone.selected.*.zone_id) : ""

  domain_name = var.vault_domain_name
}

data "aws_route53_zone" "selected" {
  count = var.create_dns_entry ? 1 : 0
  name  = "${var.hosted_zone_domain_name}."
}

module "consul_cluster" {
  source = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-cluster?ref=v0.7.4"

  cluster_name  = var.consul_cluster_name
  cluster_size  = var.consul_cluster_size
  instance_type = var.consul_instance_type

  cluster_tag_key   = var.consul_cluster_tag_key
  cluster_tag_value = var.consul_cluster_name

  ami_id    = var.ami_id == null ? data.aws_ami.vault_consul.image_id : var.ami_id
  user_data = data.template_file.user_data_consul.rendered

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnet_ids.default.ids

  allowed_ssh_cidr_blocks     = ["0.0.0.0/0"]
  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
  ssh_key_name                = var.ssh_key_name
}

data "template_file" "user_data_consul" {
  template = file("${path.module}/user-data/user-data-consul.sh")

  vars = {
    consul_cluster_tag_key   = var.consul_cluster_tag_key
    consul_cluster_tag_value = var.consul_cluster_name
  }
}

data "aws_vpc" "default" {
  default = var.use_default_vpc
  tags    = var.vpc_tags
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
  tags   = var.subnet_tags
}

data "aws_region" "current" {
}