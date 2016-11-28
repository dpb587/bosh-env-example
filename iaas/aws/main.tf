variable "environment" { type = "string" }
output "environment" { value = "${var.environment}" }

variable "gateway_private_ip" { default = "10.187.0.4" }
variable "bosh_private_ip" { default = "10.187.16.8" }

variable "region" { default = "us-east-1" }
output "region" { value = "${var.region}" }

variable "availability_zone" { default = "us-east-1a" }
output "availability_zone" { value = "${var.availability_zone}" }

#output "ssh_key" { value = "${asdf.name}" }

output "vpc_id" { value = "${aws_vpc.main.id}" }
output "vpc_cidr" { value = "${aws_vpc.main.cidr_block}" }

output "private_subnet_id" { value = "${aws_subnet.private.id}"}
output "private_subnet_cidr" { value = "${aws_subnet.private.cidr_block}"}
output "private_subnet_gateway" { value = "${cidrhost("${aws_subnet.private.cidr_block}", 1)}" }

output "public_subnet_id" { value = "${aws_subnet.public.id}"}
output "public_subnet_cidr" { value = "${aws_subnet.public.cidr_block}"}
output "public_subnet_gateway" { value = "${cidrhost("${aws_subnet.public.cidr_block}", 1)}" }

output "internal_subnet_id" { value = "${aws_subnet.internal.id}"}
output "internal_subnet_cidr" { value = "${aws_subnet.internal.cidr_block}"}
output "internal_subnet_gateway" { value = "${cidrhost("${aws_subnet.internal.cidr_block}", 1)}" }

output "aws_access_key" { value = "${aws_iam_access_key.user.id}" }
output "aws_secret_key" { value = "${aws_iam_access_key.user.secret}" }

output "ssh_name" { value = "${aws_key_pair.default.key_name}" }
output "ssh_private_key" { value = "${file("${path.module}/../../state/id_rsa")}" }

resource "aws_key_pair" "default" {
  key_name = "${var.environment}"
  public_key = "${file("${path.module}/../../state/id_rsa.pub")}"
}

resource "aws_vpc" "main" {
  cidr_block = "10.187.0.0/18"
  tags = {
    Name = "${var.environment}"
  }
}

resource "aws_internet_gateway" "main" {
  tags {
      Name = "${var.environment}"
  }
  vpc_id = "${aws_vpc.main.id}"
}

#
# subnets
#

resource "aws_subnet" "public" {
  availability_zone = "${var.availability_zone}"
  cidr_block = "10.187.0.0/20"
  map_public_ip_on_launch = true
  tags {
    Name = "${var.environment}/public"
  }
  vpc_id = "${aws_vpc.main.id}"
}

  resource "aws_route_table" "public" {
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.main.id}"
    }
    tags {
      Name = "${var.environment}/public"
    }
    vpc_id = "${aws_vpc.main.id}"
  }

  resource "aws_route_table_association" "public" {
    subnet_id = "${aws_subnet.public.id}"
    route_table_id = "${aws_route_table.public.id}"
  }

resource "aws_subnet" "private" {
  availability_zone = "${var.availability_zone}"
  cidr_block = "10.187.16.0/20"
  tags {
    Name = "${var.environment}/private"
  }
  vpc_id = "${aws_vpc.main.id}"
}

  resource "aws_route_table" "private" {
    tags {
      Name = "${var.environment}/private"
    }
    vpc_id = "${aws_vpc.main.id}"
  }

  resource "aws_route_table_association" "private" {
    subnet_id = "${aws_subnet.private.id}"
    route_table_id = "${aws_route_table.private.id}"
  }

resource "aws_subnet" "internal" {
  availability_zone = "${var.availability_zone}"
  cidr_block = "10.187.32.0/20"
  tags {
    Name = "${var.environment}/internal"
  }
  vpc_id = "${aws_vpc.main.id}"
}

  resource "aws_route_table" "internal" {
    tags {
      Name = "${var.environment}/internal"
    }
    vpc_id = "${aws_vpc.main.id}"
  }

  resource "aws_route_table_association" "internal" {
    subnet_id = "${aws_subnet.internal.id}"
    route_table_id = "${aws_route_table.internal.id}"
  }

#
# iam
#

resource "aws_iam_user" "user" {
  name = "${var.environment}"
}

resource "aws_iam_access_key" "user" {
  user = "${aws_iam_user.user.name}"
}

data "aws_iam_policy_document" "user" {
  statement {
    actions = [
      "ec2:AssociateAddress",
      "ec2:AttachVolume",
      "ec2:CreateVolume",
      "ec2:DeleteSnapshot",
      "ec2:DeleteVolume",
      "ec2:DescribeAddresses",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:DetachVolume",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:RegisterImage",
      "ec2:DeregisterImage"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_user_policy" "user" {
  name = "ec2"
  user = "${aws_iam_user.user.name}"
  policy = "${data.aws_iam_policy_document.user.json}"
}
