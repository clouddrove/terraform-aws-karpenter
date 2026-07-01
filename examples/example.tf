provider "aws" {
  region = local.region
}

locals {
  region                = "eu-west-1"
  vpc_cidr_block        = module.vpc.vpc_cidr_block
  additional_cidr_block = "172.16.0.0/16"
  name                  = "karpenter"
  environment           = "test"
}

module "vpc" {
  source  = "clouddrove/vpc/aws"
  version = "2.0.5"

  name        = "${local.name}-vpc"
  environment = local.environment
  cidr_block  = "10.10.0.0/16"
}

module "subnets" {
  source  = "clouddrove/subnet/aws"
  version = "2.0.3"

  name                = "${local.name}-subnet"
  environment         = local.environment
  nat_gateway_enabled = true
  availability_zones  = ["eu-west-1a", "eu-west-1b"]
  vpc_id              = module.vpc.vpc_id
  cidr_block          = module.vpc.vpc_cidr_block
  ipv6_cidr_block     = module.vpc.ipv6_cidr_block
  type                = "public-private"
  igw_id              = module.vpc.igw_id
}

module "keypair" {
  source  = "clouddrove/keypair/aws"
  version = "1.3.4"

  name               = "${local.name}-key"
  environment        = local.environment
  public_key         = ""
  enable_private_key = true
  enable_key_pair    = true
}

# ################################################################################
# Security Groups module call
################################################################################

module "ssh" {
  source  = "clouddrove/security-group/aws"
  version = "2.0.3"

  name        = "${local.name}-ssh"
  environment = local.environment
  vpc_id      = module.vpc.vpc_id
  new_sg_ingress_rules = [
    {
      key         = "ssh-vpc-cidr"
      from_port   = 22
      ip_protocol = "tcp"
      to_port     = 22
      cidr_ipv4   = local.vpc_cidr_block
      description = "Allow ssh traffic from VPC CIDR."
    },
    {
      key         = "ssh-additional-cidr"
      from_port   = 22
      ip_protocol = "tcp"
      to_port     = 22
      cidr_ipv4   = local.additional_cidr_block
      description = "Allow ssh traffic from additional CIDR."
    }
  ]

  ## EGRESS Rules
  new_sg_egress_rules = [
    {
      key         = "ssh-vpc-cidr"
      from_port   = 22
      ip_protocol = "tcp"
      to_port     = 22
      cidr_ipv4   = local.vpc_cidr_block
      description = "Allow ssh outbound traffic to VPC CIDR."
    },
    {
      key         = "ssh-additional-cidr"
      from_port   = 22
      ip_protocol = "tcp"
      to_port     = 22
      cidr_ipv4   = local.additional_cidr_block
      description = "Allow ssh outbound traffic to additional CIDR."
    }
  ]
}
#tfsec:ignore:aws-ec2-no-public-egress-sgr
module "http_https" {
  source  = "clouddrove/security-group/aws"
  version = "2.0.3"

  name        = "${local.name}-http-https"
  environment = local.environment
  vpc_id      = module.vpc.vpc_id
  ## INGRESS Rules
  new_sg_ingress_rules = [
    {
      key         = "ssh-vpc-cidr"
      from_port   = 22
      ip_protocol = "tcp"
      to_port     = 22
      cidr_ipv4   = local.vpc_cidr_block
      description = "Allow ssh traffic."
    },
    {
      key         = "http-vpc-cidr"
      from_port   = 80
      ip_protocol = "tcp"
      to_port     = 80
      cidr_ipv4   = local.vpc_cidr_block
      description = "Allow http traffic."
    },
    {
      key         = "https-vpc-cidr"
      from_port   = 443
      ip_protocol = "tcp"
      to_port     = 443
      cidr_ipv4   = local.vpc_cidr_block
      description = "Allow https traffic."
    }
  ]

  ## EGRESS Rules
  new_sg_egress_rules = [
    {
      key         = "all-ipv4"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow all IPv4 traffic."
    },
    {
      key         = "all-ipv6"
      ip_protocol = "-1"
      cidr_ipv6   = "::/0"
      description = "Allow all IPv6 traffic."
    }
  ]
}

################################################################################
# KMS Module call
################################################################################
#tfsec:ignore:aws-kms-auto-rotate-keys
module "kms" {
  source  = "clouddrove/kms/aws"
  version = "1.3.4"

  name                = "${local.name}-kms"
  environment         = local.environment
  enabled             = true
  description         = "KMS key for EBS of EKS nodes"
  enable_key_rotation = false
  policy              = data.aws_iam_policy_document.kms.json
}

data "aws_iam_policy_document" "kms" {
  version = "2012-10-17"
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

data "aws_caller_identity" "current" {}


################################################################################
# EKS Module call
################################################################################
module "eks" {
  source  = "clouddrove/eks/aws"
  version = "1.4.8"

  enabled = true

  name        = "${local.name}-eks"
  environment = local.environment
  # EKS
  kubernetes_version     = "1.28"
  endpoint_public_access = true
  # Networking
  vpc_id                            = module.vpc.vpc_id
  subnet_ids                        = module.subnets.private_subnet_id
  allowed_security_groups           = [module.ssh.security_group_id]
  eks_additional_security_group_ids = [module.ssh.security_group_id, module.http_https.security_group_id]
  allowed_cidr_blocks               = [local.vpc_cidr_block]

  # AWS Managed Node Group
  # Node Groups Defaults Values It will Work all Node Groups
  managed_node_group_defaults = {
    subnet_ids                          = module.subnets.private_subnet_id
    nodes_additional_security_group_ids = [module.ssh.security_group_id]
    tags = {
      "kubernetes.io/cluster/${module.eks.cluster_name}" = "shared"
      "k8s.io/cluster/${module.eks.cluster_name}"        = "shared"
    }
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size = 50
          volume_type = "gp3"
          iops        = 3000
          throughput  = 150
          encrypted   = true
          kms_key_id  = module.kms.key_arn
        }
      }
    }
  }
  managed_node_group = {
    critical = {
      name           = "${module.eks.cluster_name}-critical"
      capacity_type  = "ON_DEMAND"
      min_size       = 1
      max_size       = 2
      desired_size   = 2
      instance_types = ["t3.medium"]
    }

    application = {
      name                 = "${module.eks.cluster_name}-application"
      capacity_type        = "SPOT"
      min_size             = 1
      max_size             = 2
      desired_size         = 1
      force_update_version = true
      instance_types       = ["t3.medium"]
    }
  }

  apply_config_map_aws_auth = true
  map_additional_iam_users = [
    {
      userarn  = "arn:aws:iam::123456789:user/hello@clouddrove.com"
      username = "hello@clouddrove.com"
      groups   = ["system:masters"]
    }
  ]
}
## Kubernetes provider configuration
data "aws_eks_cluster" "this" {
  depends_on = [module.eks]
  name       = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "this" {
  depends_on = [module.eks]
  name       = module.eks.cluster_certificate_authority_data
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

module "karpenter" {
  source = "../"

  name              = "${local.name}-karpenter"
  environment       = local.environment
  namespace         = "test"
  create_namespace  = true
  karpenter_version = "v0.31.1"
  cluster_name      = module.eks.cluster_name
  depends_on        = [module.eks]
}
