# --- Security Groups ---
# Security Group for the Application Load Balancer (ALB)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Allow HTTP/HTTPS inbound to ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic (ALB needs to reach ECS tasks)
  }

  tags = var.tags
}

# Security Group for ECS Fargate Tasks
resource "aws_security_group" "ecs_task_sg" {
  name        = "${var.project_name}-${var.environment}-ecs-task-sg"
  description = "Allow inbound traffic from ALB to ECS tasks and outbound to internet/database"
  vpc_id      = var.vpc_id

  # Allow inbound from ALB on container port
  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Only allow from ALB SG
    description     = "Allow inbound from ALB"
  }

  # Allow outbound to private subnets for DB/Cache access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.database_subnet_cidrs # Allow access to DB/Cache tier
    description = "Allow outbound to database/cache subnets"
  }

  # Allow outbound to internet (via NAT Gateway, depending on subnet's route table)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound to internet (routing via NAT Gateway expected for private subnets)"
  }

  tags = var.tags
}


# --- Application Load Balancer (ALB) ---
resource "aws_lb" "application_lb" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false # Public-facing ALB
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids # ALB lives in public subnets

  tags = var.tags
}

resource "aws_lb_target_group" "ecs_target_group" {
  name        = "${var.project_name}-${var.environment}-tg"
  port        = var.container_port
  protocol    = "HTTP" # Or HTTPS if your app handles SSL, otherwise HTTP
  vpc_id      = var.vpc_id
  target_type = "ip" # Required for Fargate

  health_check {
    path                = var.health_check_path # e.g., "/health" or "/" for hello-world
    protocol            = "HTTP"
    matcher             = "200" # Expect HTTP 200 OK
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = var.tags
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.application_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    type             = "forward"
  }
}

# --- ECS Task Definition ---
resource "aws_ecs_task_definition" "app_task_definition" {
  family                   = "${var.project_name}-${var.environment}-app-task"
  network_mode             = "awsvpc" # Required for Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  # IAM Role ARNs are now passed as variables from parent module/root config
  execution_role_arn = var.ecs_task_execution_role_arn # For ECS agent permissions (pulling images, sending logs)
  task_role_arn      = var.ecs_task_role_arn           # For application's permissions (e.g., SSM, S3 access)

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-${var.environment}-container"
      image     = var.docker_image # Docker image (e.g., from ECR)
      cpu       = tonumber(var.cpu)
      memory    = tonumber(var.memory)
      essential = true
      portMappings = [
        {
          containerPort = tonumber(var.container_port)
          hostPort      = tonumber(var.container_port)
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_app_log_group.name
          "awslogs-region"        = var.aws_region # Using module's region variable
          "awslogs-stream-prefix" = "ecs"
        }
      }
      # NEW: Environment variables for database connection details
      environment = [
        {
          name  = "DB_HOST"
          value = var.db_endpoint_address
        },
        {
          name  = "DB_PORT"
          value = tostring(var.db_port)
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_USERNAME_SSM_PARAM"
          value = var.db_username_ssm_param_name # The SSM parameter name for username
        },
        {
          name  = "DB_PASSWORD_SSM_PARAM"
          value = var.db_password_ssm_param_name # The SSM parameter name for password
        }
      ]
    }
  ])

  tags = var.tags
}

# CloudWatch Log Group for ECS Task Logs
resource "aws_cloudwatch_log_group" "ecs_app_log_group" {
  name              = "/ecs/${var.project_name}-${var.environment}-app"
  retention_in_days = var.log_retention_days # Use a variable for log retention

  tags = var.tags
}


# modules/ecs_service/main.tf

# ... (Your existing Security Groups, ALB, Target Group, Listener, Task Definition, Log Group) ...

# --- ECS Service ---
resource "aws_ecs_service" "app_service" {
  name            = "${var.project_name}-${var.environment}-app-service"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.app_task_definition.arn
  desired_count   = var.ecs_desired_count # Initial desired count for the service, managed by ASG

  launch_type = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_task_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    container_name   = "${var.project_name}-${var.environment}-container"
    container_port   = var.container_port
  }

  # Add deployment_controller for zero-downtime (ECS handles blue/green or rolling updates)
  deployment_controller {
    type = "ECS" # For rolling updates
  }

  # IMPORTANT: Add these properties to help ECS recognize auto-scaling
  # These are related to ECS's ability to manage tags, which can trigger internal updates
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  # Ensure the service is created after its dependencies are ready
  depends_on = [
    aws_lb_listener.http_listener,
    aws_lb_target_group.ecs_target_group,
    aws_ecs_task_definition.app_task_definition,
  ]

  tags = var.tags
}

# --- ECS Service Auto Scaling ---

# 1. Define the Scalable Target: ECS Service Desired Count
resource "aws_appautoscaling_target" "ecs_service_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.app_service.name}" # Fixed: use cluster name, not ARN
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.ecs_min_capacity
  max_capacity       = var.ecs_max_capacity

  depends_on = [aws_ecs_service.app_service]

  tags = var.tags
}

# 2. Define Scaling Policy for CPU Utilization
resource "aws_appautoscaling_policy" "ecs_cpu_scaling_policy" {
  name               = "${var.project_name}-${var.environment}-cpu-scaling-policy"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.ecs_service_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_scale_target.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.ecs_target_cpu_utilization_percent
    scale_in_cooldown  = 300 # 5 minutes
    scale_out_cooldown = 60  # 1 minute
  }

  depends_on = [aws_appautoscaling_target.ecs_service_scale_target]
}

# 3. Define Scaling Policy for Memory Utilization
resource "aws_appautoscaling_policy" "ecs_memory_scaling_policy" {
  name               = "${var.project_name}-${var.environment}-memory-scaling-policy"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.ecs_service_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_scale_target.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.ecs_target_memory_utilization_percent
    scale_in_cooldown  = 300 # 5 minutes
    scale_out_cooldown = 60  # 1 minute
  }

  depends_on = [aws_appautoscaling_target.ecs_service_scale_target]
}

# --- ECS Service Auto Scaling (Custom Metric : Requests) ---

resource "aws_appautoscaling_policy" "ecs_custom_metric_scaling_policy" {
  count = var.enable_custom_metric_autoscaling ? 1 : 0 # Only create if custom scaling is enabled

  name               = "${var.project_name}-${var.environment}-requests-scaling-policy" # Updated name
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.ecs_service_scale_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service_scale_target.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    customized_metric_specification {
      metric_name = var.custom_metric_filter_metric_name # References the metric filter's name
      namespace   = var.custom_metric_filter_namespace   # References the metric filter's namespace
      statistic   = "Sum"                                # Sum the 'Count' over the period (e.g., 1 minute)
      unit        = "Count"                              # The unit of the metric

      # No dimensions needed if the metric filter doesn't emit with dimensions
    }
    target_value       = var.custom_scaling_target_value
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }

  # Ensure this policy depends on the metric filter
  depends_on = [
    aws_appautoscaling_target.ecs_service_scale_target
  ]
}