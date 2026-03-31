# AWS ECS Scheduled Task Module

This module creates the foundational ECS resources needed for a one-shot AWS ECS scheduled task, including a task definition, task IAM role, optional inline task IAM policy, CloudWatch log group, and task security group.

## What This Module Creates

- 1 CloudWatch log group
- 1 ECS task IAM role
- Optional inline IAM role policy for the ECS task
- 1 ECS task definition
- 1 ECS task security group

## Usage

```hcl
module "ecs_scheduled_task" {
  source = "git::ssh://git@github.com:karoosoftware/terraform-ecs-scheduled-task-module.git?ref=<commit-sha>"

  log_group_name           = "/ecs/margana-puzzle-generator-preprod"
  task_role_name           = "margana-puzzle-generator-task-role-preprod"
  family                   = "margana-puzzle-generator-preprod"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::123456789012:role/ecsTaskExecutionRole"
  container_name           = "margana-puzzle-generator-preprod"
  image                    = "123456789012.dkr.ecr.eu-west-2.amazonaws.com/margana-preprod:latest"
  command                  = ["--smoke-test"]
  aws_region               = "eu-west-2"
  vpc_id                   = "vpc-0123456789abcdef0"
  task_security_group_name = "margana-puzzle-generator-task-sg-preprod"

  task_role_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:eu-west-2:123456789012:secret:postmark/email-token-preprod*"
        ]
      }
    ]
  })

  tags = {
    Environment = "preprod"
    Application = "Margana"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `log_group_name` | Name of the CloudWatch log group for the ECS task. | `string` | n/a | yes |
| `log_retention_in_days` | Number of days to retain CloudWatch log events. | `number` | `30` | no |
| `task_role_name` | Name of the IAM role assumed by the ECS task. | `string` | n/a | yes |
| `family` | Family name of the ECS task definition. | `string` | n/a | yes |
| `cpu` | CPU units used by the task. | `string` | n/a | yes |
| `memory` | Memory in MiB used by the task. | `string` | n/a | yes |
| `execution_role_arn` | ARN of the ECS task execution role. | `string` | n/a | yes |
| `container_name` | Name of the container in the task definition. | `string` | n/a | yes |
| `image` | Container image URI to run. | `string` | n/a | yes |
| `command` | Optional command to pass to the container. | `list(string)` | `[]` | no |
| `aws_region` | AWS region for CloudWatch Logs configuration. | `string` | n/a | yes |
| `vpc_id` | ID of the VPC where the ECS task will run. | `string` | n/a | yes |
| `task_security_group_name` | Name of the security group attached to the ECS task. | `string` | n/a | yes |
| `task_role_policy_json` | Optional inline IAM policy JSON to attach to the ECS task role. | `string` | `null` | no |
| `tags` | Tags to apply to resources created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `task_role_arn` | ARN of the IAM role assumed by the ECS task |
| `task_role_name` | Name of the IAM role assumed by the ECS task |
| `task_definition_arn` | ARN of the ECS task definition |
| `task_definition_family` | Family name of the ECS task definition |
| `task_security_group_id` | ID of the security group attached to the ECS task |
| `task_security_group_name` | Name of the security group attached to the ECS task |

## Notes

- This module creates the task-level resources for an ECS scheduled task workload.
- The module can optionally attach a single inline IAM policy to the task role via `task_role_policy_json`.
- Scheduling and task triggering are expected to be handled by a higher-level module, such as one using EventBridge.
- Shared VPC networking such as VPC endpoints is better managed by a VPC or platform networking module.

## Release Process

- Update the root `VERSION` file in the same change that should be released, using semantic versioning such as `1.0.1`, `1.1.0`, or `2.0.0`.
- Push the change to `develop` and let the `terraform-validate` workflow pass.
- Open a pull request from `develop` to `main` and let the `terraform-validate` workflow pass again.
- Merge the pull request to `main`.
- Pushing to `main` triggers the automated release workflow, which:
  - reads `VERSION`,
  - checks that tag `v<VERSION>` does not already exist,
  - creates and pushes the tag,
  - creates the GitHub release automatically.
- If `VERSION` has not been updated and the tag already exists, validation and release will fail.
- Consume released versions from other Terraform repos by pinning the module source with the released tag, for example:

```bash
source = "git::ssh://git@github.com:karoosoftware/terraform-ecs-scheduled-task-module.git?ref=v1.0.0"
```

## Prerequisites

- Terraform 1.x
- AWS provider configured in the root module
- IAM permissions to create ECS task definitions, IAM roles, CloudWatch log groups, and security groups
