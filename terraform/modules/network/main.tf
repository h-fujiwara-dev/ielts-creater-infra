locals {
  cloud_map_namespace_name = coalesce(var.cloud_map_namespace_name, "ielts-creater-${var.environment}.local")
}

data "aws_ami" "nat_instance" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-arm64"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ielts-creater-${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "ielts-creater-${var.environment}-igw"
  }
}

resource "aws_subnet" "public" {
  count = length(var.azs)

  vpc_id                  = aws_vpc.this.id
  availability_zone       = var.azs[count.index]
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "ielts-creater-${var.environment}-public-${var.azs[count.index]}"
  }
}

resource "aws_subnet" "private" {
  count = length(var.azs)

  vpc_id            = aws_vpc.this.id
  availability_zone = var.azs[count.index]
  cidr_block        = var.private_subnet_cidrs[count.index]

  tags = {
    Name = "ielts-creater-${var.environment}-private-${var.azs[count.index]}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "ielts-creater-${var.environment}-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = length(var.azs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# --- NAT Instance（NAT Gatewayの代替。固定費を月$45前後→月$5前後に削減） ---

resource "aws_security_group" "nat" {
  name        = "ielts-creater-${var.environment}-nat-sg"
  description = "NAT Instance: allow all traffic from private subnets, allow all egress"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "All traffic from within the VPC (private subnets routed through this instance)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ielts-creater-${var.environment}-nat-sg"
  }
}

resource "aws_iam_role" "nat_ssm" {
  name = "ielts-creater-${var.environment}-nat-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "nat_ssm" {
  role       = aws_iam_role.nat_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "nat_ssm" {
  name = "ielts-creater-${var.environment}-nat-ssm-profile"
  role = aws_iam_role.nat_ssm.name
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "ielts-creater-${var.environment}-nat-eip"
  }
}

resource "aws_instance" "nat" {
  ami                    = data.aws_ami.nat_instance.id
  instance_type          = var.nat_instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.nat.id]
  iam_instance_profile   = aws_iam_instance_profile.nat_ssm.name

  # NATとして機能させるため送信元/宛先チェックを無効化する
  source_dest_check = false

  user_data = templatefile("${path.module}/templates/nat-instance-user-data.sh.tftpl", {
    vpc_cidr = var.vpc_cidr
  })

  tags = {
    Name = "ielts-creater-${var.environment}-nat-instance"
  }
}

resource "aws_eip_association" "nat" {
  instance_id   = aws_instance.nat.id
  allocation_id = aws_eip.nat.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "ielts-creater-${var.environment}-private-rt"
  }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat.primary_network_interface_id
}

resource "aws_route_table_association" "private" {
  count = length(var.azs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ECS Service Discovery（modules/ecsが登録し、modules/api-gatewayのVPC Link private integrationが参照する）
resource "aws_service_discovery_private_dns_namespace" "this" {
  name = local.cloud_map_namespace_name
  vpc  = aws_vpc.this.id
}
