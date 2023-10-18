#Module      : LABEL
#Description : Terraform label module variables.
variable "name" {
  type        = string
  default     = ""
  description = "Name  (e.g. `app` or `cluster`)."
}

variable "environment" {
  type        = string
  default     = ""
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "repository" {
  type        = string
  default     = "https://github.com/clouddrove/terraform-aws-vpc"
  description = "Terraform current module repo"
}

variable "label_order" {
  type        = list(any)
  default     = ["environment", "name"]
  description = "Label order, e.g. `name`,`application`."
}

variable "managedby" {
  type        = string
  default     = "hello@clouddrove.com"
  description = "ManagedBy, eg 'CloudDrove'"
}

variable "enabled" {
  type    = bool
  default = true
}



## IAM
variable "provider_url" {
  type        = string
  default     = ""
  description = "URL of the OIDC Provider. Use provider_urls to specify several URLs."
}

variable "provider_urls" {
  type        = list(string)
  default     = []
  description = "List of URLs of the OIDC Providers"
}

variable "role_name_prefix" {
  type        = string
  default     = null
  description = "IAM role name prefix"
}

variable "role_description" {
  type        = string
  default     = ""
  description = "IAM Role description"
}

variable "role_path" {
  type        = string
  default     = "/"
  description = "Path of IAM role"
}

variable "role_permissions_boundary_arn" {
  type        = string
  default     = null
  description = "Permissions boundary ARN to use for IAM role"
}

variable "max_session_duration" {
  type        = number
  default     = 3600
  description = "Maximum CLI/API session duration in seconds between 3600 and 43200"
}

variable "role_policy_arns" {
  type        = list(string)
  default     = []
  description = "List of ARNs of IAM policies to attach to IAM role"
}

variable "number_of_role_policy_arns" {
  type        = number
  default     = null
  description = "Number of IAM policies to attach to IAM role"
}


variable "oidc_fully_qualified_subjects" {
  type        = set(string)
  default     = ["system:serviceaccount:karpenter:karpenter"]
  description = "The fully qualified OIDC subjects to be added to the role policy"
}

variable "oidc_subjects_with_wildcards" {
  type        = set(string)
  default     = []
  description = "The OIDC subject using wildcards to be added to the role policy"
}

variable "oidc_fully_qualified_audiences" {
  type        = set(string)
  default     = []
  description = "The audience to be added to the role policy. Set to sts.amazonaws.com for cross-account assumable role. Leave empty otherwise."
}

variable "force_detach_policies" {
  description = "Whether policies should be detached from this role when destroying"
  type        = bool
  default     = false
}

variable "cluster_name" {
  type        = string
  default     = "test"
  description = "The name of EKS cluster"
}

variable "namespace" {
  type        = string
  default     = null
  description = ""
}

variable "create_namespace" {
  type        = bool
  default     = false
  description = ""
}

variable "eks_cluster_endpoint" {
  type        = string
  default     = null
  description = "eks cluster endpoint"
}

variable "eks_worker_iam_role_name" {
  type        = string
  default     = "arn:aws:iam::xxxxxxxxxxxx:role/KarpenterControllerRole-clouddrove-Karpenter"
  description = "eks iam role name"
}

variable "karpenter_version" {
  type        = string
  default     = "0.5.1"
  description = "Helm version of karpenter"
}
