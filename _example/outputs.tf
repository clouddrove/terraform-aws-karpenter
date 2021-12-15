output "chart" {
  value       = module.karpenter.chart
  description = "Chart name to be installed. The chart name can be local path, a URL to a chart, or the name of the chart if repository is specified. It is also possible to use the <repository>/<chart> format here if you are running Terraform on a system that the repository has been added to with helm repo add but this is not."
}
output "tags" {
  value       = module.karpenter.tags
  description = "A mapping of tags to assign to the resource."
}

