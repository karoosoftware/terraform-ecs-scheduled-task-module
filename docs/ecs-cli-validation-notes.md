# Terraform ECS Scheduled Task Module Handover

This document is the handover note for building the shared `terraform-ecs-scheduled-task-module`. The AWS shape has already been validated manually with the AWS CLI against a real ECS Fargate task running privately in a VPC. The next step is to codify that working shape into Terraform without changing behavior unnecessarily.

## Current Status

The current Terraform split is now:

- `terraform-ecs-cluster-module`
  - owns the ECS cluster
- `terraform-vpc-module`
  - owns shared VPC networking, including:
  - interface VPC endpoints for ECR API, ECR DKR, and CloudWatch Logs
  - the S3 gateway endpoint
  - the shared endpoint security group
  - ingress rules allowing ECS task security groups to reach the endpoints on TCP `443`
- `terraform-ecs-scheduled-task-module`
  - currently owns:
  - CloudWatch log group
  - ECS task IAM role
  - ECS task definition
  - ECS task security group

The private networking path has been re-tested after moving the endpoint resources into the VPC module. A one-off ECS Fargate task run completed successfully using:

- private subnet networking
- `assignPublicIp=DISABLED`
- the ECS task security group
- VPC interface endpoints and S3 gateway endpoint managed by the VPC module

This confirms that private image pull and CloudWatch Logs access are working with the current module split.

## Module Intent

The module should provision a reusable ECS scheduled task implementation for AWS with:

- an ECS task definition
- an ECS task role
- CloudWatch log group integration
- private image pull support from ECR via existing VPC-level networking
- input-driven integration with an existing ECS cluster, VPC, subnets, route tables, ECR repository, and execution role

This module is for one-shot ECS workloads, not long-running ECS services.

## Validated AWS Shape

The following behavior has already been proven manually:

- GitHub Actions can build and push the container image to ECR
- ECS can run the task on Fargate
- the task can pull the image privately from ECR
- CloudWatch Logs integration works
- the container smoke test runs successfully
- the task exits with exit code `0`

CloudWatch output observed during successful validation:

- `Starting Margana Puzzle Generator Task smoke test`
- `Smoke test completed successfully.`

## Validated Runtime Model

- Workload type:
  - one-shot scheduled ECS task
- Launch type:
  - `FARGATE`
- Network mode:
  - `awsvpc`
- Subnet model:
  - private subnet
- Public IP:
  - `assignPublicIp=DISABLED`
- Private connectivity requirement:
  - VPC interface endpoints plus S3 gateway endpoint

## Validated Task Definition Shape

The manually validated task definition shape is:

- family:
  - `margana-puzzle-generator`
- cpu:
  - `256`
- memory:
  - `512`
- execution role:
  - `arn:aws:iam::992468223519:role/ecsTaskExecutionRole`
- task role:
  - `arn:aws:iam::992468223519:role/margana-puzzle-generator-task-role`
- container name:
  - `margana-puzzle-generator`
- image:
  - `992468223519.dkr.ecr.eu-west-2.amazonaws.com/margana-preprod:latest`
- smoke test command:
  - `["--smoke-test"]`
- log group:
  - `/ecs/margana-puzzle-generator`
- log stream prefix:
  - `ecs`

The module should make these values configurable rather than hardcoded.

## Validated Networking Requirements

Private ECS Fargate startup required all of the following:

- VPC DNS support enabled
- VPC DNS hostnames enabled
- interface VPC endpoint for `com.amazonaws.eu-west-2.ecr.api`
- interface VPC endpoint for `com.amazonaws.eu-west-2.ecr.dkr`
- interface VPC endpoint for `com.amazonaws.eu-west-2.logs`
- gateway VPC endpoint for `com.amazonaws.eu-west-2.s3`
- endpoint security group allowing inbound TCP `443` from the ECS task security group
- ECS task security group allowing outbound traffic

Important lesson:

- `ecr.api` alone is not enough
- `ecr.dkr` alone is not enough
- the S3 gateway endpoint was also required for private image pull to succeed

## AWS Resources Used During Validation

These values come from the validated preprod environment and can be used to guide the Terraform design. They should not all be hardcoded into the module.

### Existing Platform Resources

- ECS cluster:
  - `margana`
- VPC:
  - `vpc-02440e21b92afff6d`
- private subnet:
  - `subnet-07a21be8c3ad7a2c6`
- private route table:
  - `rtb-0e9c0106b1d1b225b`
- ECR repository:
  - `margana-preprod`
- ECS task execution role:
  - `arn:aws:iam::992468223519:role/ecsTaskExecutionRole`

### Resources Created Manually and Likely Candidates for Terraform

- ECS task role:
  - `arn:aws:iam::992468223519:role/margana-puzzle-generator-task-role`
- ECS task security group:
  - `sg-061577e8cb4f419e8`
- VPC endpoint security group:
  - `sg-0a7016d94d2796436`
- ECR API interface endpoint:
  - `vpce-0e1b65d63a1404791`
- ECR DKR interface endpoint:
  - `vpce-0a1cbfb1bc0884630`
- CloudWatch Logs interface endpoint:
  - created manually in `eu-west-2`
- S3 gateway endpoint:
  - attached to `rtb-0e9c0106b1d1b225b`
- CloudWatch log group:
  - `/ecs/margana-puzzle-generator`
- ECS task definition family and revision:
  - `margana-puzzle-generator:1`

### Resources Now Codified In Terraform

- ECS cluster
  - moved into `terraform-ecs-cluster-module`
- ECS task role
  - codified in `terraform-ecs-scheduled-task-module`
- CloudWatch log group
  - codified in `terraform-ecs-scheduled-task-module`
- ECS task definition
  - codified in `terraform-ecs-scheduled-task-module`
- ECS task security group
  - codified in `terraform-ecs-scheduled-task-module`
- VPC endpoint security group
  - codified in `terraform-vpc-module`
- SG ingress rule from task SG to endpoint SG on TCP `443`
  - codified in `terraform-vpc-module`
- ECR API interface endpoint
  - codified in `terraform-vpc-module`
- ECR DKR interface endpoint
  - codified in `terraform-vpc-module`
- CloudWatch Logs interface endpoint
  - codified in `terraform-vpc-module`
- S3 gateway endpoint
  - codified in `terraform-vpc-module`

## Recommended Module Boundary

The module should own:

- ECS task role
- task-role policy attachments or inline policy inputs
- CloudWatch log group
- ECS task definition
- ECS task security group

The module should accept as inputs:

- cluster name or ARN
- VPC ID
- private subnet IDs
- ECR repository URL or repository name
- execution role ARN
- container name
- image tag or full image URI
- CPU and memory
- command override
- environment variables
- task policy statements or task policy attachments

The module should probably not create by default:

- the VPC
- the subnets
- the route tables
- the ECS cluster
- the ECR repository
- the task execution role

Those are better treated as platform inputs unless a higher-level stack composes them together.

## Import / Codification Candidates

These were the main resources to import into Terraform state or recreate declaratively and then adopt carefully:

- ECS task role
- ECS task definition
- CloudWatch log group
- ECS task security group

## Suggested First Terraform Slice

The first implemented Terraform slice for the scheduled task module was:

1. Create module skeleton:
   - `main.tf`
   - `variables.tf`
   - `outputs.tf`
   - `README.md`
   - `versions.tf`
2. Model the minimum working resources:
   - CloudWatch log group
   - ECS task role
   - ECS task definition
3. Add task-specific networking resources:
   - task SG
4. Expose inputs for cluster, VPC, subnets, execution role, and image URI
5. Only after the working shape is represented, consider cleanup/refactor work such as:
   - immutable image tags
   - optional endpoint creation flags
   - richer IAM composition

## Design Constraints For The Module

- Keep the first implementation aligned with the already validated AWS shape.
- Prefer inputs over hidden conventions.
- Do not make the module specific to `margana`.
- Do not assume long-running HTTP workloads.
- Keep private networking as a first-class use case.
- Avoid baking GitHub Actions concerns into the module.

## Known Follow-Up Work

These items are intentionally not solved yet, but the module design should leave room for them:

- codifying IAM policy attachments or inline policies for the ECS task role
- adding task environment variable support
- adding task policy composition inputs
- switching from `:latest` to immutable image tags or digests
- optional EventBridge schedule resources in a higher-level module
- optional SES/SNS/S3 task permissions based on workload needs
- writing examples for a minimal private Fargate scheduled task

## Practical Next Step

The next Terraform slice for `terraform-ecs-scheduled-task-module` should focus on IAM permissions for the ECS task role. The task now runs successfully with private networking in place, but the task role currently has no workload-specific policy attachments yet.

## Practical Conclusion

The ECS pattern itself is proven, including private startup through VPC endpoints now managed by the VPC module. The next agent should focus on codifying workload-specific IAM permissions and any remaining task-level configuration in `terraform-ecs-scheduled-task-module` without moving shared networking concerns back into it.
