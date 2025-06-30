
## Missing details for EKS & Instance connection
### Internet, app, etc

# Data section
data "http" "my_ip_address" {
  url = "http://ipv4.icanhazip.com"
}

# Alternative backup for ip address
data "http" "my_ip_address_2" {
  url = "https://ipv4.wtfismyip.com/text"
}

# Network section
resource "aws_vpc" "aws_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = "false"

  tags = {
    Name = "${var.project_tag}_VPC"
  }
}

resource "aws_subnet" "aws_subnet" {
  vpc_id                  = aws_vpc.aws_vpc.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.aws_availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_tag}_SUBNET"
  }
}

resource "aws_internet_gateway" "aws_igw" {
  vpc_id = aws_vpc.aws_vpc.id

  tags = {
    Name = "${var.project_tag}_IGW"
  }
}

resource "aws_route_table" "aws_rt" {
  vpc_id = aws_vpc.aws_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws_igw.id
  }

  tags = {
    Name = "${var.project_tag}_RT"
  }
}

resource "aws_main_route_table_association" "aws_rta" {
  vpc_id         = aws_vpc.aws_vpc.id
  route_table_id = aws_route_table.aws_rt.id
}

# Security Group section
resource "aws_security_group" "aws_sg" {
  name   = "${var.project_tag}_SG"
  vpc_id = aws_vpc.aws_vpc.id

  tags = {
    Name = "${var.project_tag}_security_group"
  }
}

## Ingress rules section
resource "aws_security_group_rule" "my_ip_rule" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["${chomp(data.http.my_ip_address.response_body)}/32"]
  security_group_id = aws_security_group.aws_sg.id
}

resource "aws_security_group_rule" "vpc_rule" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.aws_sg.id
}

resource "aws_security_group_rule" "additional_cidr_rules" {
  count = var.additional_public_cidrs != null ? 1 : 0 # If null, do not create the rule

  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = var.additional_public_cidrs
  security_group_id = aws_security_group.aws_sg.id
}

## Egress rules section
resource "aws_security_group_rule" "all_egress_rule" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.aws_sg.id
}
