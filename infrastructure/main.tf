# ------------------------------------------------------------------------------
# define the VPC
# ------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = "${merge(map("Name", "${var.namespace}-vpc"), var.tags)}"
}

# seal off the default NACL
resource "aws_default_network_acl" "main_default" {
  default_network_acl_id = "${aws_vpc.main.default_network_acl_id}"
  tags                   = "${merge(map("Name", "${var.namespace}-default"), var.tags)}"
}

# seal off the default security group
resource "aws_default_security_group" "main_default" {
  vpc_id = "${aws_vpc.main.id}"
  tags   = "${merge(map("Name", "${var.namespace}-default"), var.tags)}"
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
  tags   = "${merge(map("Name", "${var.namespace}-gateway"), var.tags)}"
}

# ------------------------------------------------------------------------------
# define the public subnet
# ------------------------------------------------------------------------------

resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${cidrsubnet(var.vpc_cidr, 10, 40)}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  tags                    = "${merge(map("Name", "${var.namespace}-public"), var.tags)}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  tags = "${merge(map("Name", "${var.namespace}-public"), var.tags)}"
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_network_acl" "public" {
  vpc_id     = "${aws_vpc.main.id}"
  subnet_ids = ["${aws_subnet.public.id}"]
  tags       = "${merge(map("Name", "${var.namespace}-public"), var.tags)}"
}

resource "aws_network_acl_rule" "public_ephemeral_out" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public_http_out" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 101
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_https_out" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 102
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public_ephemeral_in" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "public_http_in" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 101
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_https_in" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 102
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Docker needs tcp 2377 and 7946, and udp 7946 and 4789
# between each node in the swarm
resource "aws_network_acl_rule" "public_docker_in_1" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.private.cidr_block}"
  from_port      = 2377
  to_port        = 2377
}

resource "aws_network_acl_rule" "public_docker_in_2" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 201
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.private.cidr_block}"
  from_port      = 7946
  to_port        = 7946
}

resource "aws_network_acl_rule" "public_docker_in_3" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 202
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.private.cidr_block}"
  from_port      = 7946
  to_port        = 7946
}

resource "aws_network_acl_rule" "public_docker_in_4" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 203
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.private.cidr_block}"
  from_port      = 4789
  to_port        = 4789
}

resource "aws_network_acl_rule" "public_docker_out_1" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 200
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.private.cidr_block}"
  from_port      = 2377
  to_port        = 2377
}

resource "aws_network_acl_rule" "public_docker_out_2" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 201
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.private.cidr_block}"
  from_port      = 7946
  to_port        = 7946
}

resource "aws_network_acl_rule" "public_docker_out_3" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 202
  egress         = true
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.private.cidr_block}"
  from_port      = 7946
  to_port        = 7946
}

resource "aws_network_acl_rule" "public_docker_out_4" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 203
  egress         = true
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.private.cidr_block}"
  from_port      = 4789
  to_port        = 4789
}

# ------------------------------------------------------------------------------
# NAT gateway - Allows traffic out of the private subnet
# ------------------------------------------------------------------------------
resource "aws_eip" "nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "main" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${aws_subnet.public.id}"
  depends_on    = ["aws_internet_gateway.main"]
  tags          = "${merge(map("Name", "${var.namespace}-nat-gateway"), var.tags)}"
}

# ------------------------------------------------------------------------------
# define the private subnet
# ------------------------------------------------------------------------------

resource "aws_subnet" "private" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${cidrsubnet(var.vpc_cidr, 10, 41)}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"
  tags                    = "${merge(map("Name", "${var.namespace}-private"), var.tags)}"
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.main.id}"
  }

  tags = "${merge(map("Name", "${var.namespace}-private"), var.tags)}"
}

resource "aws_route_table_association" "private_route_table_association" {
  subnet_id      = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_network_acl" "private" {
  vpc_id     = "${aws_vpc.main.id}"
  subnet_ids = ["${aws_subnet.private.id}"]
  tags       = "${merge(map("Name", "${var.namespace}-private"), var.tags)}"
}

resource "aws_network_acl_rule" "ephemeral_out" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_http_out" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 101
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "private_https_out" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 102
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "ephemeral_in" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_http_in" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 101
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "https_in" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 102
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Docker needs tcp 2377 and 7946, and udp 7946 and 4789
# between each node in the swarm
resource "aws_network_acl_rule" "private_docker_in_1" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.public.cidr_block}"
  from_port      = 2377
  to_port        = 2377
}

resource "aws_network_acl_rule" "private_docker_in_2" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 201
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.public.cidr_block}"
  from_port      = 7946
  to_port        = 7946
}

resource "aws_network_acl_rule" "private_docker_in_3" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 202
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.public.cidr_block}"
  from_port      = 7946
  to_port        = 7946
}

resource "aws_network_acl_rule" "private_docker_in_4" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 203
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.public.cidr_block}"
  from_port      = 4789
  to_port        = 4789
}

resource "aws_network_acl_rule" "private_docker_out_1" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 200
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.public.cidr_block}"
  from_port      = 2377
  to_port        = 2377
}

resource "aws_network_acl_rule" "private_docker_out_2" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 201
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.public.cidr_block}"
  from_port      = 7946
  to_port        = 7946
}

resource "aws_network_acl_rule" "private_docker_out_3" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 202
  egress         = true
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.public.cidr_block}"
  from_port      = 7946
  to_port        = 7946
}

resource "aws_network_acl_rule" "private_docker_out_4" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 203
  egress         = true
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "${aws_subnet.public.cidr_block}"
  from_port      = 4789
  to_port        = 4789
}
