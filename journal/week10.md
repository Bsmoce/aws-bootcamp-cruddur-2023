# Week 10 — CloudFormation Part 1
## Create an S3 bucket
**we creat an s3 bucket to contain all of our artifacts for CloudFormation**

```sh
aws s3 mk s3://cfn-bsharp
export CFN_BUCKET="cfn-bsharp"
gp env CFN_BUCKET="cfn-bsharp"
```

## Setting up CloudFormation

We create this CloudFormation template `aws/cfn/template.yaml` to create an ECS Cluster named "Bsharp" with Fargate as the capacity provider:

```yml
AWSTemplateFormatVersion: 2010-09-09
Description: |
  Setup ECS Cluster
Resources:
  ECSCluster: 
    Type: 'AWS::ECS::Cluster'
    Properties:
      ClusterName: Bsharp
      CapacityProviders:
        - FARGATE
```


## AWS CloudFormation Linter

Linter is a tool that validate AWS CloudFormation yaml/json templates against the [AWS CloudFormation Resource Specification](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-resource-specification.html) and additional
checks. Includes checking valid values for resource properties and best practices.

## AWS CloudFormation Guard 
**Validate Cloud Environments with Policy-as-Code**

AWS CloudFormation Guard is an open-source general-purpose policy-as-code evaluation tool. It provides developers with a simple-to-use, yet powerful and expressive domain-specific language (DSL) to define policies and enables developers to validate JSON- or YAML- formatted structured data with those policies. 


We add the installations in `.gitpod.yml`:

```yml
  - name: cfn
    before: |
      pip install cfn-lint
      cargo install cfn-guard
      gem install cfn-toml
```

## ECS Guard Rules

we add `aws/cfn/task-definition.guard`:

```
aws_ecs_cluster_configuration {
  rules = [
    {
      rule = "task_definition_encryption"
      description = "Ensure task definitions are encrypted"
      level = "error"
      action {
        type = "disallow"
        message = "Task definitions in the Amazon ECS cluster must be encrypted"
      }
      match {
        type = "ecs_task_definition"
        expression = "encrypt == false"
      }
    },
    {
      rule = "network_mode"
      description = "Ensure Fargate tasks use awsvpc network mode"
      level = "error"
      action {
        type = "disallow"
        message = "Fargate tasks in the Amazon ECS cluster must use awsvpc network mode"
      }
      match {
        type = "ecs_task_definition"
        expression = "network_mode != 'awsvpc'"
      }
    },
    {
      rule = "execution_role"
      description = "Ensure Fargate tasks have an execution role"
      level = "error"
      action {
        type = "disallow"
        message = "Fargate tasks in the Amazon ECS cluster must have an execution role"
      }
      match {
        type = "ecs_task_definition"
        expression = "execution_role == null"
      }
    },
  ]
}
```
