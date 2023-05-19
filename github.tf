locals {
  name = var.repo_name
  repo_name = var.repo_name
}

resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "this" {
  title      = "Flux"
  repository = local.repo_name
  key        = tls_private_key.flux.public_key_openssh
  read_only  = "true"
}