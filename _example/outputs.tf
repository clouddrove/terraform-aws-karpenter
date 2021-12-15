output "chart" {
  value       = module.karpenter.chart
  description = "Chart name to be installed. The chart name can be local path, a URL to a chart, or the name of the chart if repository is specified. It is also possible to use the <repository>/<chart> format here if you are running Terraform on a system that the repository has been added to with helm repo add but this is not."
}
output "repository_username" {
  value       = module.karpenter.repository_username
  description = "Username for HTTP basic authentication against the repository."
}
output "version" {
  value       = module.karpenter.version
  description = "Specify the exact chart version to install. If this is not specified, the latest version is installed."
}
