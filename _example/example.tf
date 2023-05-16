provider "aws" {
  region = "eu-west-1"
}

locals {
  tags = {
    "kubernetes.io/cluster/test-eks-cluster" = "shared"
  }
}



module "vpc" {
  source  = "clouddrove/vpc/aws"
  version = "1.3.0"

  name        = "vpc"
  environment = "test"
  label_order = ["environment", "name"]
  vpc_enabled = true

  cidr_block = "10.10.0.0/16"
}

module "subnets" {
  source  = "clouddrove/subnet/aws"
  version = "1.3.0"

  name        = "subnets"
  environment = "test"
  label_order = ["environment", "name"]
  tags        = local.tags
  enabled     = true

  nat_gateway_enabled = true
  availability_zones  = ["eu-west-1a", "eu-west-1b"]
  vpc_id              = module.vpc.vpc_id
  cidr_block          = module.vpc.vpc_cidr_block
  ipv6_cidr_block     = module.vpc.ipv6_cidr_block
  type                = "public-private"
  igw_id              = module.vpc.igw_id
}


module "eks" {
  source  = "clouddrove/eks/aws"
  version = "12.7.1"

  name        = "karpenter-eks"
  environment = "test"
  label_order = ["environment", "name"]
  enabled     = true

  # EKS
  kubernetes_version        = "1.25"
  endpoint_private_access   = true
  endpoint_public_access    = true
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  oidc_provider_enabled     = true
  # Networking
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.subnets.private_subnet_id
  allowed_cidr_blocks     = ["10.0.0.0/16"]

  ################################################################################
  # AWS Managed Node Group
  ################################################################################
  # Node Groups Defaults Values It will Work all Node Groups
  managed_node_group_defaults = {
    subnet_ids                          = module.subnets.private_subnet_id
    tags = {
      Example = "test"
    }
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size = 50
          volume_type = "gp3"
          iops        = 3000
          throughput  = 150
        }
      }
    }
  }
  managed_node_group = {
    tools = {
      min_size       = 1
      max_size       = 7
      desired_size   = 2
      instance_types = ["t3a.medium"]
    }

    spot = {
      name          = "spot"
      capacity_type = "SPOT"

      min_size             = 1
      max_size             = 7
      desired_size         = 1
      force_update_version = true
      instance_types       = ["t3.medium", "t3a.medium"]
    }
  }
  apply_config_map_aws_auth = true

}

################################################################################
# Kubernetes provider configuration
################################################################################

data "aws_eks_cluster" "this" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_certificate_authority_data
}
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

module "karpenter" {

  source      = "../"
  name        = "karpenter"
  environment = "test"
  label_order = ["environment", "name"]

  namespace         = "test"
  create_namespace  = true
  karpenter_version = "0.6.0"

  cluster_name             = module.eks.eks_cluster_id
  eks_cluster_endpoint     = module.eks.eks_cluster_endpoint
  eks_worker_iam_role_name = module.eks.iam_role_name
  provider_url             = module.eks.oidc_issuer_url
  depends_on               = [module.eks]
}
