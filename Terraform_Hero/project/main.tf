# ==========================================================================================
provider "aws" {
  profile = "default"
}
# ==============================| Module Configuration with Network |=======================
module "vpc_default" {
  source = "../modules/aws_network"
}
# ==============================| Security Group and Public Cidrs blocks |==================
resource "aws_security_group" "wizard_rds" {
  name        = "dynamic_security_group"
  description = "Bacis Security Group"
  vpc_id      = module.vpc_default.vpc_id
  dynamic "ingress" {
    for_each = ["22", "80", "8081", "3000", "443", "5432"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "Dynamic Security Group"
    Owner = "Artem Burmak"
  }
}

#==============================| Master password for RDS PostgeSQL|========================
resource "random_string" "rds_password" {
  length           = 13
  special          = true
  override_special = "/@"
}

resource "aws_ssm_parameter" "rds_password" {
  name        = "/dev/postgresql"
  description = "Master password for RDS PostgreSQL"
  type        = "SecureString"
  value       = random_string.rds_password.result
}

data "aws_ssm_parameter" "my_rds_password" {
  name       = "/dev/postgresql"
  depends_on = [aws_ssm_parameter.rds_password]
}
# ==============================| DRS PostgreSQL Database |================================
resource "aws_db_instance" "postgres" {
  identifier             = "dev-rds"
  storage_type           = "gp2"
  db_name                = "postgresql_db"
  engine                 = "postgres"
  engine_version         = "13.7"
  instance_class         = "db.t3.micro"
  username               = "artem"
  password               = data.aws_ssm_parameter.my_rds_password.value
  parameter_group_name   = "default.postgres13"
  allocated_storage      = 5
  skip_final_snapshot    = true
  apply_immediately      = true
  db_subnet_group_name   = aws_db_subnet_group.wizard_rds.id
  vpc_security_group_ids = [aws_security_group.wizard_rds.id]
}

resource "aws_db_subnet_group" "wizard_rds" {
  name       = "main"
  subnet_ids = slice(values(module.vpc_default.private_subnet_ids), 0, 2)

  tags = {
    Name = "My DB subnet group"
  }
}
#==============================| Application Load Balancer |================================
resource "aws_lb" "this" {
  name                       = "${var.name}-main-alb"
  internal                   = false
  load_balancer_type         = "application"
  ip_address_type            = "ipv4"
  security_groups            = [aws_security_group.wizard_rds.id]
  subnets                    = slice(values(module.vpc_default.public_subnet_ids), 0, 3)
  enable_deletion_protection = var.deletion_protection

  tags = {
    Name = "ALB for ECS"
  }
}

resource "aws_lb_target_group" "client" {
  name        = "${var.name}-client"
  target_type = "ip"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc_default.vpc_id

  health_check {
    path     = "/"
    protocol = "HTTP"
    matcher  = "200"
  }
}

resource "aws_lb_listener" "alb" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.default_validation.certificate_arn

  default_action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.client.arn
      }
    }
    target_group_arn = aws_lb_target_group.client.arn
  }

  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.client
    ]
  }
}

resource "aws_lb_listener" "alb2" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "redirect"
    target_group_arn = aws_lb_target_group.client.arn
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  lifecycle {
    replace_triggered_by = [
      aws_lb_target_group.client
    ]
  }
}
# ==============================| ACM Certificate |==========================================
resource "aws_acm_certificate" "default" {
  domain_name               = "aryanes.pp.ua"
  subject_alternative_names = ["*.aryanes.pp.ua"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
# ==============================| AWS Route 53 |=============================================
data "aws_route53_zone" "this" {
  name         = "aryanes.pp.ua"
  private_zone = false
}

resource "aws_route53_record" "default" {
  for_each = {
    for dvo in aws_acm_certificate.default.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this.zone_id
}

resource "aws_acm_certificate_validation" "default_validation" {
  certificate_arn         = aws_acm_certificate.default.arn
  validation_record_fqdns = [for record in aws_route53_record.default : record.fqdn]
}

resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = data.aws_route53_zone.this.name
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}
# ==============================| Elastic Container Service |================================
resource "aws_ecs_cluster" "main" {
  name = "ECS-Cluster"
}

resource "aws_ecs_task_definition" "main" {
  family = "service"
  container_definitions = jsonencode([
    {
      name      = "jira-client-prod"
      image     = "aryanesj/jira_client_prod"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8081
          hostPort      = 8081
        }
      ]
    }
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "main" {
  name            = "main-ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.client.id
    container_name   = "jira-client-prod"
    container_port   = 8081
  }

  network_configuration {
    subnets          = slice(values(module.vpc_default.public_subnet_ids), 0, 3)
    security_groups  = [aws_security_group.wizard_rds.id]
    assign_public_ip = true
  }
}
