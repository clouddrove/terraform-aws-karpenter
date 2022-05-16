
# Managed By : CloudDrove
# Description : This Script is used to create VPC, Internet Gateway and Flow log.
# Copyright @ CloudDrove. All Right Reserved.


#Module      : labels
#Description : This terraform module is designed to generate consistent label names and tags
#              for resources. You can use terraform-labels to implement a strict naming
#              convention.
module "labels" {
  source  = "clouddrove/labels/aws"
  version = "0.15.0"

  name        = var.name
  environment = var.environment
  managedby   = var.managedby
  label_order = var.label_order
  repository  = var.repository
}


locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  urls = [
    for url in compact(distinct(concat(var.provider_urls, [var.provider_url]))) :
    replace(url, "https://", "")
  ]
  number_of_role_policy_arns = coalesce(var.number_of_role_policy_arns, length(var.role_policy_arns))
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "assume_role_with_oidc" {
  count = var.enabled ? 1 : 0

  dynamic "statement" {
    for_each = local.urls

    content {
      effect = "Allow"

      actions = ["sts:AssumeRoleWithWebIdentity"]

      principals {
        type = "Federated"

        identifiers = ["arn:${data.aws_partition.current.partition}:iam::${local.aws_account_id}:oidc-provider/${statement.value}"]
      }

      dynamic "condition" {
        for_each = length(var.oidc_fully_qualified_subjects) > 0 ? local.urls : []

        content {
          test     = "StringEquals"
          variable = "${statement.value}:sub"
          values   = ["system:serviceaccount:karpenter:karpenter"]
        }
      }

      dynamic "condition" {
        for_each = length(var.oidc_subjects_with_wildcards) > 0 ? local.urls : []

        content {
          test     = "StringLike"
          variable = "${statement.value}:sub"
          values   = var.oidc_subjects_with_wildcards
        }
      }

      dynamic "condition" {
        for_each = length(var.oidc_fully_qualified_audiences) > 0 ? local.urls : []

        content {
          test     = "StringLike"
          variable = "${statement.value}:aud"
          values   = var.oidc_fully_qualified_audiences
        }
      }
    }
  }
}

resource "aws_iam_role" "this" {
  count = var.enabled ? 1 : 0

  name                 = "karpenter-controller-${var.cluster_name}"
  name_prefix          = var.role_name_prefix
  description          = var.role_description
  path                 = var.role_path
  max_session_duration = var.max_session_duration

  force_detach_policies = var.force_detach_policies
  permissions_boundary  = var.role_permissions_boundary_arn

  assume_role_policy = join("", data.aws_iam_policy_document.assume_role_with_oidc.*.json)

  tags = module.labels.tags
}

resource "aws_iam_role_policy_attachment" "custom" {
  count = var.enabled ? local.number_of_role_policy_arns : 0

  role       = join("", aws_iam_role.this.*.name)
  policy_arn = var.role_policy_arns[count.index]
}


resource "aws_iam_role_policy" "karpenter_contoller" {
  count = var.enabled ? 1 : 0
  name  = format("%s-%s", module.labels.id, var.cluster_name)
  role  = join("", aws_iam_role.this.*.name)
#tfsec:ignore:aws-iam-no-policy-wildcards
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "iam:PassRole",
          "ec2:TerminateInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}



data "aws_iam_policy" "ssm_managed_instance" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "karpenter_ssm_policy" {
  count      = var.enabled ? 1 : 0
  role       = var.eks_worker_iam_role_name
  policy_arn = data.aws_iam_policy.ssm_managed_instance.arn
}

resource "aws_iam_instance_profile" "karpenter" {
  count = var.enabled ? 1 : 0
  name  = "KarpenterNodeInstanceIAMProfile-${var.cluster_name}"
  role  = var.eks_worker_iam_role_name
}


resource "helm_release" "karpenter" {
  count = var.enabled ? 1 : 0

  name             = "karpenter"
  repository       = "https://charts.karpenter.sh"
  chart            = "karpenter"
  version          = var.karpenter_version #
  namespace        = var.namespace
  create_namespace = var.create_namespace

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = join("", aws_iam_role.this.*.arn)
  }

  set {
    name  = "controller.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "controller.clusterEndpoint"
    value = var.eks_cluster_endpoint
  }
}
