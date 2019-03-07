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

resource "aws_network_acl_rule" "public_service_in" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 103
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 8080
  to_port        = 8080
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

# ------------------------------------------------------------------------------
# Setup swarm manager instance in the "public" subnet
# ------------------------------------------------------------------------------

resource "aws_iam_role" "swarm_master" {
  name        = "swarm-master"
  description = "privileges for the swarm master"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "swarm_master_ssm" {
  role       = "${aws_iam_role.swarm_master.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "swarm_master_sm" {
  role       = "${aws_iam_role.swarm_master.id}"
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_instance_profile" "swarm_master" {
  name = "swarm-master"
  role = "${aws_iam_role.swarm_master.id}"
}

resource "aws_security_group" "swarm_master" {
  vpc_id      = "${aws_vpc.main.id}"
  name_prefix = "swarm-master"
  description = "allow docker and http/https"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow access to the deployed web application
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.private.cidr_block}"]
  }

  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.private.cidr_block}"]
  }

  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    cidr_blocks = ["${aws_subnet.private.cidr_block}"]
  }

  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = ["${aws_subnet.private.cidr_block}"]
  }

  # access redis
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.private.cidr_block}"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.private.cidr_block}"]
  }

  egress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.private.cidr_block}"]
  }

  egress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    cidr_blocks = ["${aws_subnet.private.cidr_block}"]
  }

  egress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = ["${aws_subnet.private.cidr_block}"]
  }
}

resource "aws_instance" "swarm_master" {
  ami                         = "${data.aws_ami.target_ami.id}"
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.public.id}"
  associate_public_ip_address = true

  root_block_device = {
    volume_type = "standard"
    volume_size = 8
  }

  vpc_security_group_ids = ["${aws_security_group.swarm_master.id}"]

  iam_instance_profile = "${aws_iam_instance_profile.swarm_master.name}"

  tags        = "${merge(map("Name","swarm-master"), var.tags)}"
  volume_tags = "${merge(map("Name","swarm-master"), var.tags)}"

  user_data = <<EOF
#!/bin/bash
yum update -y -q
amazon-linux-extras install docker -y
service docker start
docker swarm init --advertise-addr $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

aws --region ${var.aws_region} secretsmanager create-secret --name swarm-token --secret-string $(docker swarm join-token worker -q) 2>/dev/null

aws --region ${var.aws_region} secretsmanager update-secret --secret-id swarm-token --secret-string $(docker swarm join-token worker -q) 2>/dev/null

mkdir /tmp/data
EOF
}

# ------------------------------------------------------------------------------
# Setup swarm worker instances in the "private" subnet
# ------------------------------------------------------------------------------

resource "aws_iam_role" "swarm_worker" {
  name        = "swarm-worker"
  description = "privileges for the swarm worker"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "swarm_worker_ssm" {
  role       = "${aws_iam_role.swarm_worker.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "swarm_worker_sm" {
  role       = "${aws_iam_role.swarm_worker.id}"
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_instance_profile" "swarm_worker" {
  name = "swarm-worker"
  role = "${aws_iam_role.swarm_worker.id}"
}

resource "aws_security_group" "swarm_worker" {
  vpc_id      = "${aws_vpc.main.id}"
  name_prefix = "swarm-worker"
  description = "allow docker"

  ingress {
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.public.cidr_block}"]
  }

  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.public.cidr_block}"]
  }

  ingress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    cidr_blocks = ["${aws_subnet.public.cidr_block}"]
  }

  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = ["${aws_subnet.public.cidr_block}"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.public.cidr_block}"]
  }

  egress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    cidr_blocks = ["${aws_subnet.public.cidr_block}"]
  }

  egress {
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    cidr_blocks = ["${aws_subnet.public.cidr_block}"]
  }

  egress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = ["${aws_subnet.public.cidr_block}"]
  }
}

resource "aws_instance" "swarm_worker" {
  count                       = "${var.worker_count}"
  ami                         = "${data.aws_ami.target_ami.id}"
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.private.id}"
  associate_public_ip_address = false

  root_block_device = {
    volume_type = "standard"
    volume_size = 8
  }

  vpc_security_group_ids = ["${aws_security_group.swarm_worker.id}"]

  iam_instance_profile = "${aws_iam_instance_profile.swarm_worker.name}"

  tags        = "${merge(map("Name","swarm-worker-${count.index}"), var.tags)}"
  volume_tags = "${merge(map("Name","swarm-worker-${count.index}"), var.tags)}"

  user_data = <<EOF
#!/bin/bash
yum update -y -q
amazon-linux-extras install docker -y
service docker start

sleep ${var.sleep_seconds}

TOKEN=$(aws --region ${var.aws_region} secretsmanager get-secret-value --secret-id swarm-token --query "SecretString" --output text)
echo "TOKEN=$TOKEN"

docker swarm join --token $TOKEN ${aws_instance.swarm_master.private_ip}:2377
EOF
}
