## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_name | The name of EKS cluster | `string` | `"test"` | no |
| create\_namespace | n/a | `bool` | `false` | no |
| eks\_cluster\_endpoint | eks cluster endpoint | `string` | `null` | no |
| eks\_worker\_iam\_role\_name | eks iam role name | `string` | `"test"` | no |
| enabled | n/a | `bool` | `true` | no |
| environment | Environment (e.g. `prod`, `dev`, `staging`). | `string` | `""` | no |
| force\_detach\_policies | Whether policies should be detached from this role when destroying | `bool` | `false` | no |
| karpenter\_version | Helm version of karpenter | `string` | `"0.5.1"` | no |
| label\_order | Label order, e.g. `name`,`application`. | `list(any)` | <pre>[<br>  "environment",<br>  "name"<br>]</pre> | no |
| managedby | ManagedBy, eg 'CloudDrove' | `string` | `"hello@clouddrove.com"` | no |
| max\_session\_duration | Maximum CLI/API session duration in seconds between 3600 and 43200 | `number` | `3600` | no |
| name | Name  (e.g. `app` or `cluster`). | `string` | `""` | no |
| namespace | n/a | `string` | `null` | no |
| number\_of\_role\_policy\_arns | Number of IAM policies to attach to IAM role | `number` | `null` | no |
| oidc\_fully\_qualified\_audiences | The audience to be added to the role policy. Set to sts.amazonaws.com for cross-account assumable role. Leave empty otherwise. | `set(string)` | `[]` | no |
| oidc\_fully\_qualified\_subjects | The fully qualified OIDC subjects to be added to the role policy | `set(string)` | <pre>[<br>  "system:serviceaccount:karpenter:karpenter"<br>]</pre> | no |
| oidc\_subjects\_with\_wildcards | The OIDC subject using wildcards to be added to the role policy | `set(string)` | `[]` | no |
| provider\_url | URL of the OIDC Provider. Use provider\_urls to specify several URLs. | `string` | `""` | no |
| provider\_urls | List of URLs of the OIDC Providers | `list(string)` | `[]` | no |
| repository | Terraform current module repo | `string` | `"https://github.com/clouddrove/terraform-aws-vpc"` | no |
| role\_description | IAM Role description | `string` | `""` | no |
| role\_name\_prefix | IAM role name prefix | `string` | `null` | no |
| role\_path | Path of IAM role | `string` | `"/"` | no |
| role\_permissions\_boundary\_arn | Permissions boundary ARN to use for IAM role | `string` | `null` | no |
| role\_policy\_arns | List of ARNs of IAM policies to attach to IAM role | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| chart | n/a |
| repository | Repository URL where to locate the requested chart. |
| tags | n/a |
| version | Specify the exact chart version to install. If this is not specified, the latest version is installed. |

