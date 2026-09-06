variable "project" {
  description = "Project name used for resource naming"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "repo" {
  description = "GitHub repository in the form 'org/repo' for the OIDC trust policy"
  type        = string
}

variable "environments" {
  description = "List of environments to create state buckets for"
  type        = list(string)
  default     = ["dev", "uat", "prod"]
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}