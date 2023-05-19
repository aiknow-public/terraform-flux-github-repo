locals {
  name      = var.repo_name
  repo_name = var.repo_name
  org_name  = "bosch-top98-ai-know"
  # SSH
  known_hosts = "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="
}

//Deploy key

resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "this" {
  title      = "Flux ${var.environment}"
  repository = local.repo_name
  key        = tls_private_key.flux.public_key_openssh
  read_only  = "true"
}

//Deployment folders

resource "github_repository_file" "deploy-folder-readme" {
  repository          = local.repo_name
  branch              = "main"
  file                = "kubernetes/${var.environment}/README.md"
  content             = "Use this folder for flux deployments to dev"
  commit_message      = "Managed by Terraform"
  commit_author       = "Atlantis"
  commit_email        = "No-Reply@bosch.com"
  overwrite_on_create = false
}

//webhook
//cannot be created with Github App Auth,so we write the data to Parameter Store

resource "aws_ssm_parameter" "webhook_data" {
  name        = "/${var.environment}/github-webhook/${var.repo_name}"
  description = "Data for the Github webhook to be created manually"
  type        = "SecureString"
  value       = <<-EOT
      gitrepo: https://github.com/bosch-top98-ai-know/${var.repo_name}/settings/hooks
      webhook_url: ${var.webhookURL}${data.kubernetes_resource.receiver.object.status.webhookPath}
      secret: ${kubernetes_secret_v1.webhook_secret.data.token}
  EOT
}

data "kubernetes_resource" "receiver" {
  api_version = "notification.toolkit.fluxcd.io/v1"
  kind        = "Receiver"

  metadata {
    name      = local.name
    namespace = "flux-system"
  }
}