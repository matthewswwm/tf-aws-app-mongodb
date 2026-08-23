# network.tf
# Refactored into another file for better readability

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

resource "aws_subnet" "mongodb" {
  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.instance_subnet_cidr
  availability_zone = var.aws_availability_zone_list[0]

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

## EKS-specific

resource "aws_subnet" "eks_public" {
  count = length(var.eks_public_subnet_cidrs)

  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.eks_public_subnet_cidrs[count.index]
  availability_zone = var.aws_availability_zone_list[count.index]

  tags = {
    Name                                            = "${var.project_tag}_EKS_SUBNET_${upper(var.aws_availability_zone_list[count.index])}"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
    "kubernetes.io/role/elb"                        = "1"
  }
}

resource "aws_subnet" "eks_private" {
  count = length(var.eks_private_subnet_cidrs)

  vpc_id            = aws_vpc.aws_vpc.id
  cidr_block        = var.eks_private_subnet_cidrs[count.index]
  availability_zone = var.aws_availability_zone_list[count.index]

  tags = {
    Name                                            = "${var.project_tag}_EKS_SUBNET_${upper(var.aws_availability_zone_list[count.index])}"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"               = "1"
  }
}

resource "aws_eip" "eks_private_nat" {
  count  = length(var.eks_private_subnet_cidrs)
  domain = "vpc"

  tags = {
    Name = "${var.project_tag}_NAT_EIP_${upper(var.aws_availability_zone_list[count.index])}"
  }
}

resource "aws_nat_gateway" "eks_private" {
  count = length(var.eks_private_subnet_cidrs)

  allocation_id = aws_eip.eks_private_nat[count.index].id
  subnet_id     = aws_subnet.eks_public[count.index].id

  tags = {
    Name = "${var.project_tag}_NAT_GW_${upper(var.aws_availability_zone_list[count.index])}"
  }

  depends_on = [aws_internet_gateway.aws_igw]
}

resource "aws_route_table" "eks_private" {
  count  = length(var.eks_private_subnet_cidrs)
  vpc_id = aws_vpc.aws_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks_private[count.index].id
  }

  tags = {
    Name = "${var.project_tag}_EKS_PRIVATE_RT_${upper(var.aws_availability_zone_list[count.index])}"
  }
}

resource "aws_route_table_association" "eks_private" {
  count = length(var.eks_private_subnet_cidrs)

  subnet_id      = aws_subnet.eks_private[count.index].id
  route_table_id = aws_route_table.eks_private[count.index].id
}

# Security Group section
## MongoDB Instance SG rule
resource "aws_security_group" "mongodb" {
  name   = "${var.project_tag}_mongoDB_SG"
  vpc_id = aws_vpc.aws_vpc.id

  tags = {
    Name = "${var.project_tag}_mongoDB_SG"
  }
}

# Unused, but kept for reference
resource "aws_vpc_security_group_ingress_rule" "mongodb_additional_cidr" {
  for_each = var.additional_public_cidrs != null ? toset(var.additional_public_cidrs) : []

  ip_protocol       = "-1"
  cidr_ipv4         = each.value
  security_group_id = aws_security_group.mongodb.id
}

resource "aws_vpc_security_group_ingress_rule" "mongodb_ssh" {
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.mongodb.id
}

resource "aws_vpc_security_group_ingress_rule" "mongodb_eks_private" {
  count = length(var.eks_private_subnet_cidrs)

  ip_protocol       = "-1"
  cidr_ipv4         = var.eks_private_subnet_cidrs[count.index]
  security_group_id = aws_security_group.mongodb.id
}

## EKS SG rule
resource "aws_security_group" "eks" {
  name   = "${var.project_tag}_eks_SG"
  vpc_id = aws_vpc.aws_vpc.id

  tags = {
    Name = "${var.project_tag}_eks_SG"
  }
}

## "Global Rules"
resource "aws_vpc_security_group_ingress_rule" "my_ip" {
  for_each = {
    mongodb = aws_security_group.mongodb.id
    eks     = aws_security_group.eks.id
  }

  ip_protocol       = "-1"
  cidr_ipv4         = "${chomp(data.http.my_ip_address.response_body)}/32"
  security_group_id = each.value
}

# For reference only
# resource "aws_vpc_security_group_ingress_rule" "http" {
#   for_each = {
#     mongodb = aws_security_group.mongodb.id
#     eks     = aws_security_group.eks.id
#   }

#   from_port         = 80
#   to_port           = 80
#   ip_protocol       = "tcp"
#   cidr_ipv4         = "0.0.0.0/0"
#   security_group_id = each.value
# }

## Egress rules section
# For ease of development & access during setup
# resource "aws_vpc_security_group_ingress_rule" "vpc_self" {
#   for_each = {
#     mongodb = aws_security_group.mongodb.id
#     eks     = aws_security_group.eks.id
#   }

#   ip_protocol       = "-1"
#   cidr_ipv4         = var.vpc_cidr
#   security_group_id = each.value
# }

resource "aws_vpc_security_group_egress_rule" "all" {
  for_each = {
    mongodb = aws_security_group.mongodb.id
    eks     = aws_security_group.eks.id
  }

  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = each.value
}
