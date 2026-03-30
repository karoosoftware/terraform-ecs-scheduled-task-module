output "task_role_arn" {
  description = "ARN of the IAM role assumed by the ECS task."
  value       = aws_iam_role.task.arn
}

output "task_role_name" {
  description = "Name of the IAM role assumed by the ECS task."
  value       = aws_iam_role.task.name
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition."
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Family name of the ECS task definition."
  value       = aws_ecs_task_definition.this.family
}

output "task_security_group_id" {
  description = "ID of the security group attached to the ECS task."
  value       = aws_security_group.task.id
}

output "task_security_group_name" {
  description = "Name of the security group attached to the ECS task."
  value       = aws_security_group.task.name
}