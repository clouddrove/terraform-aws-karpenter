output "chart" {
  value       = join("", helm_release.karpenter.*.chart)
}

output "repository" {
  value       = join("", helm_release.karpenter.*.repository)
  description = "Repository URL where to locate the requested chart."
}
output "version" {
  value       = join("", helm_release.karpenter.*.version)
  description = "Specify the exact chart version to install. If this is not specified, the latest version is installed."
}
output "tags" {
  value = module.labels.tags
}
