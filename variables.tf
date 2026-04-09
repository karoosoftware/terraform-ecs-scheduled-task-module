variable "log_group_name" {
  description = "Name of the CloudWatch log group for the ECS task."
  type        = string
}

variable "log_retention_in_days" {
  description = "Number of days to retain CloudWatch log events."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to resources created by this module."
  type        = map(string)
  default     = {}
}

variable "task_role_name" {
  description = "Name of the IAM role assumed by the ECS task."
  type        = string
}

variable "family" {
  description = "Family name of the ECS task definition."
  type        = string
}

variable "cpu" {
  description = "CPU units used by the task."
  type        = string
}

variable "memory" {
  description = "Memory in MiB used by the task."
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution role."
  type        = string
}

variable "container_name" {
  description = "Name of the container in the task definition."
  type        = string
}

variable "image" {
  description = "Container image URI to run."
  type        = string
}

variable "command" {
  description = "Optional command to pass to the container."
  type        = list(string)
  default     = []
}

variable "aws_region" {
  description = "AWS region for CloudWatch Logs configuration."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the ECS task will run."
  type        = string
}

variable "task_security_group_name" {
  description = "Name of the security group attached to the ECS task."
  type        = string
}

variable "task_role_policy_json" {
  description = "Optional inline IAM policy JSON to attach to the ECS task role."
  type        = string
  default     = null
}

variable "env_vars" {
  description = "Environment variables to pass to the container."
  type        = map(string)
  default     = {}
}