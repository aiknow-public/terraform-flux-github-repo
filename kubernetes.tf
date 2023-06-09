locals {
  target_namespace = var.target_namespace != null ? "targetNamespace: ${var.target_namespace}" : ""
}
//repo

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
          ${var.repo_ref_type}: ${var.repo_ref_value}
        secretRef:
          name: ${kubernetes_secret_v1.repo_secret.metadata[0].name}
        url: ssh://git@github.com/${var.org_name}/${local.repo_name}
  EOT
  )
}

resource "kubernetes_secret_v1" "repo_secret" {
  metadata {
    name      = "${local.name}-repo-secret"
    namespace = "flux-system"
  }

  data = {
    identity       = tls_private_key.flux.private_key_pem
    "identity.pub" = tls_private_key.flux.public_key_openssh
    known_hosts    = local.known_hosts
  }
}

//webhook

resource "kubernetes_manifest" "receiver" {
  manifest = yamldecode(<<-EOT
      apiVersion: notification.toolkit.fluxcd.io/v1
      kind: Receiver
      metadata:
        name: ${local.name}
        namespace: flux-system
      spec:
        type: github
        events:
          - "ping"
          - "push"
        secretRef:
          name: ${kubernetes_secret_v1.webhook_secret.metadata[0].name}
        resources:
          - kind: GitRepository
            name: ${local.name}
  EOT
  )

  wait {
    fields = {
      "status.webhookPath" = "*"
    }
  }
}

resource "kubernetes_secret_v1" "webhook_secret" {
  metadata {
    name      = "${local.name}-webhook-secret"
    namespace = "flux-system"
  }

  data = {
    token = random_password.webhook_secret.result
  }
}

resource "random_password" "webhook_secret" {
  length  = 32
  special = false
}

//kustomization

resource "kubernetes_manifest" "kustomization" {
  manifest = yamldecode(<<-EOT
      apiVersion: kustomize.toolkit.fluxcd.io/v1
      kind: Kustomization
      metadata:
        name: ${local.name}
        namespace: flux-system
      spec:
        ${local.target_namespace}
        interval: 1m0s
        path: ./kubernetes/${var.environment}
        prune: true
        sourceRef:
          kind: GitRepository
          name: ${local.name}
        dependsOn:
          - name: infrastructure
          - name: common
        postBuild:
          substituteFrom:
            - kind: ConfigMap
              name: common-variables
            - kind: Secret
              name: secretvariables
  EOT
  )
}
