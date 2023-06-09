locals {
  name      = replace(var.repo_name, "_", "-") # a lowercase RFC 1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
  repo_name = var.repo_name
  # SSH
  known_hosts = "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="
}

//Deploy key

resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "this" {
  count = var.access_github ? 1 : 0
  title      = "Flux ${var.environment}"
  repository = local.repo_name
  key        = tls_private_key.flux.public_key_openssh
  read_only  = "true"
}

//webhook
resource "github_repository_webhook" "webhook" {
  count = var.access_github ? 1 : 0
  repository = var.repo_name
  configuration {
    url          = "${var.webhookURL}${data.kubernetes_resource.receiver.object.status.webhookPath}"
    content_type = "json"
    secret       = kubernetes_secret_v1.webhook_secret.data.token
    insecure_ssl = false
  }
  active = true
  events = ["push"]
}

data "kubernetes_resource" "receiver" {
  api_version = "notification.toolkit.fluxcd.io/v1"
  kind        = "Receiver"

  metadata {
    name      = local.name
    namespace = "flux-system"
  }

  depends_on = [kubernetes_manifest.receiver]
}
