variable "aws_profile" {
  type        = string
  description = "AWS Profile"
}

variable "s3_artifact_upload_policy_name" {
  type        = string
  description = "S3 artifact upload policy"
}

variable "s3_artifact_upload_description" {
  type        = string
  description = "S3 artifact upload policy description"
}

variable "gh_actions_role_name" {
  type        = string
  description = "Name of github actions role"
}

variable "ghactions_codedeploy_policy_name" {
  type        = string
  description = "GHactions code deploy policy name"
}

variable "ghactions_codedeploy_policy_description" {
  type        = string
  description = "GH actions codeploy policy description"
}

variable "aws_region" {
  type        = string
  description = "AWS Region name"
}

variable "aws_account_id" {
  type        = number
  description = "Account ID number of AWS Account"
}

variable "codedeploy_application_name" {
  type        = string
  description = "Codedeploy Application name"
}

variable "codedeploy_deployment_group" {
  type        = string
  description = "Deployment Group in Codedeploy Application"
}

variable "artifact_s3_arn" {
  type        = string
  description = "ARN number of S3 Bucket that stores artifacts"
}

variable "ec2_codedeploy_policy_name" {
  type        = string
  description = "EC2 codedeploy policy name"
}
variable "ec2_codedeploy_policy_name_description" {
  type        = string
  description = "EC2 codedeploy policy description"
  default     = "Customer Managed Policy to provide permissions to EC2 instances to access Code Deploy"
}

variable "domain_name" {
  type        = string
  description = "Domain Name"
}

variable "zone_name" {
  type        = string
  description = "Zone Name"
}