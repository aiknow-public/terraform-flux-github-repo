locals {
  name = var.repo_name
  repo_name = var.repo_name
  org_name = "bosch-top98-ai-know"
  # SSH
  known_hosts = "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="
}

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

//webhook

resource "github_repository_webhook" "this" {
  repository = local.repo_name
  name = "Flux ${var.environment}"
  configuration {
    url          = "${var.webhookURL}${kubernetes_manifest.receiver.object.status.webhookPath}"
    content_type = "json"
    insecure_ssl = false
    secret = kubernetes_secret_v1.webhook_secret.data.token
  }
  active = true
  events = ["push"]
}