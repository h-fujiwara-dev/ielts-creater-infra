locals {
  container_name = "api"
  name_prefix    = "ielts-creater-${var.environment}"
}

data "aws_region" "current" {}

# --- ECS Cluster（Fargate Spotのみ。オンデマンドFargateは使わずコストを抑える） ---

resource "aws_ecs_cluster" "this" {
  name = local.name_prefix
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
    base              = 0
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.log_retention_days
}

# --- IAM ---

resource "aws_iam_role" "execution" {
  name = "${local.name_prefix}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# secretsmanager:GetSecretValueはAmazonECSTaskExecutionRolePolicyに含まれないため個別に付与する
resource "aws_iam_role_policy" "execution_secrets" {
  count = length(var.secrets) > 0 ? 1 : 0

  name = "secrets-access"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = distinct([for s in var.secrets : s.secret_arn])
    }]
  })
}

resource "aws_iam_role" "task" {
  name = "${local.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# S3StorageService（backend #00044）とPollyListeningAudioSynthesizer（backend #00033）が
# アプリケーションコード内でDefaultCredentialsProviderを使う際にこのタスクロールが使われる
resource "aws_iam_role_policy" "task" {
  name = "app-permissions"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${var.s3_bucket_arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["polly:SynthesizeSpeech"]
        Resource = "*"
      }
    ]
  })
}

# --- Security Group ---

resource "aws_security_group" "ecs" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "ECS Fargate tasks: allow inbound from the API Gateway VPC Link only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "From API Gateway VPC Link"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.vpclink_security_group_id]
  }

  egress {
    description = "All outbound (NAT instance routes to the internet)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ecs-sg"
  }
}

# --- Cloud Map Service Discovery ---
# API GatewayのHTTP API private integrationがポート情報を取得できるようSRVレコードで登録する
# （AレコードだとDiscoverInstancesにAWS_INSTANCE_PORTが含まれない）

resource "aws_service_discovery_service" "this" {
  name = local.container_name

  dns_config {
    namespace_id = var.cloud_map_namespace_id

    dns_records {
      type = "SRV"
      ttl  = 10
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# --- Task Definition / Service ---

resource "aws_ecs_task_definition" "this" {
  family                   = local.name_prefix
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true

      portMappings = [{
        containerPort = var.container_port
        protocol      = "tcp"
      }]

      environment = [for k, v in var.environment_variables : { name = k, value = v }]
      secrets     = [for s in var.secrets : { name = s.name, valueFrom = s.valueFrom }]

      # ECSはこの結果をCloud Mapのcustom health statusへ反映する（health_check_custom_config参照）
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/actuator/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "api"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "this" {
  name            = local.name_prefix
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
    base              = 0
  }

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs.id]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.this.arn
    container_name = local.container_name
    container_port = var.container_port
  }

  depends_on = [
    aws_ecs_cluster_capacity_providers.this,
    aws_iam_role_policy_attachment.execution_managed,
  ]
}
