variable "repo_name" {}
variable "environment" {}
variable "webhookURL" {}
variable "target_namespace" {
  default = "playground"
}
variable "access_github" {
  default = true
}
variable "org_name" {
  default = "bosch-top98-ai-know"
}