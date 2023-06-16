variable "repo_name" {}
variable "environment" {}
variable "webhookURL" {
  default = ""
}
variable "target_namespace" {
  default = "playground"
}
variable "access_github" {
  default = true
}
variable "org_name" {
  default = "bosch-top98-ai-know"
}
variable "repo_ref_type" {
  default = "branch"
}
variable "repo_ref_value" {
  default = "main"
}