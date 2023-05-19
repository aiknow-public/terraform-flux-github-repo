resource "kubernetes_manifest" "repo" {
  manifest = yamldecode(<<-EOT
      apiVersion: source.toolkit.fluxcd.io/v1
      kind: GitRepository
      metadata:
        name: ${local.name}
        namespace: flux-system
      spec:
        interval: 10m0s
        ref:
          branch: main
        secretRef:
          name: ${kubernetes_secret_v1.repo_secret.metadata.name}
        url: ssh://git@github.com/${local.org_name}/${local.repo_name}
  EOT
  )
}

resource "kubernetes_secret_v1" "repo_secret" {
  metadata {
    name = local.name
    namespace = "flux-system"
  }

  data = {
    identity = tls_private_key.flux.private_key_pem
    "identity.pub" = tls_private_key.flux.public_key_openssh
    known_hosts = local.known_hosts
  }
}