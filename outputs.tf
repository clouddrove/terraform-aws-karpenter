output "chart" {
  value       = join("", helm_release.karpenter.chart)
  description = "Chart name to be installed. The chart name can be local path, a URL to a chart, or the name of the chart if repository is specified. It is also possible to use the <repository>/<chart> format here if you are running Terraform on a system that the repository has been added to with helm repo add but this is not."
}
output "repository" {
  value       = join("", helm_release.karpenter.repository)
  description = "Repository URL where to locate the requested chart."
}
output "repository_key_file" {
  value       = join("", helm_release.karpenter.repository_key_file)
  description = "The repositories cert key file."
}
output "repository_cert_file" {
  value       = join("", helm_release.karpenter.repository_cert_file)
  description = "The repositories cert file."
}
output "repository_username" {
  value       = join("", helm_release.karpenter.repository_username)
  description = "Username for HTTP basic authentication against the repository."
}
output "version" {
  value       = join("", helm_release.karpenter.version)
  description = "Specify the exact chart version to install. If this is not specified, the latest version is installed."
}
