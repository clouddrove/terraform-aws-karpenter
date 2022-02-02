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
  version = "0.15.0"

  name        = "vpc"
  environment = "test"
  label_order = ["environment", "name"]
  vpc_enabled = true

  cidr_block = "10.10.0.0/16"
}

module "subnets" {
  source  = "clouddrove/subnet/aws"
  version = "0.15.0"

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
  version = "0.15.1"

  ## Tags
  name        = "eks-karpenter"
  environment = "test"
  label_order = ["environment", "name"]
  enabled     = true

  ## Network
  vpc_id                              = module.vpc.vpc_id
  eks_subnet_ids                      = module.subnets.public_subnet_id
  worker_subnet_ids                   = module.subnets.private_subnet_id
  endpoint_private_access             = false
  endpoint_public_access              = true
  public_access_cidrs                 = ["0.0.0.0/0"]
  cluster_encryption_config_resources = ["secrets"]
  associate_public_ip_address         = false
  ## volume_size
  volume_size = 30

  ondemand_enabled      = false
  spot_enabled          = false
  spot_schedule_enabled = false


  #node_group
  node_group_enabled = true
  node_groups = {
    tools = {
      node_group_name           = "autoscale"
      subnet_ids                = module.subnets.private_subnet_id
      ami_type                  = "AL2_x86_64"
      node_group_volume_size    = 100
      node_group_instance_types = ["t3.large"]
      kubernetes_labels         = {}
      kubernetes_version        = "1.21"
      node_group_desired_size   = 1
      node_group_max_size       = 1
      node_group_min_size       = 1
      node_group_capacity_type  = "ON_DEMAND"
      node_group_volume_type    = "gp2"
      node_group_taint_key      = "test"
      node_group_taint_value    = "value"
      node_group_taint_effect   = "NO_SCHEDULE"

    }
  }


  ## Cluster
  wait_for_capacity_timeout = "15m"
  apply_config_map_aws_auth = true
  kubernetes_version        = "1.21"
  oidc_provider_enabled     = true
  ## Health Checks
  cpu_utilization_high_threshold_percent = 80
  cpu_utilization_low_threshold_percent  = 20
  health_check_type                      = "EC2"
}


data "aws_eks_cluster" "cluster" {
  name = module.eks.eks_cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.eks_cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
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
