data "terraform_remote_state" "iaas" {
  backend = "local"
  config = {
    path = "${path.module}/../../../../state/iaas.tfstate"
  }
}

variable "private_ip" { default = "10.187.0.8" }
output "private_ip" { value = "${var.private_ip}" }

variable "vpn_cidr" { default = "10.187.240.0/24" }
output "vpn_cidr" { value = "${var.vpn_cidr}" }

output "securitygroup" { value = "${aws_security_group.main.id}" }
output "securitygroup_ssh" { value = "${aws_security_group.ssh.id}" }

output "public_ip" { value = "${aws_eip.main.public_ip}" }

resource "aws_eip" "main" {
  vpc      = true
}

resource "aws_security_group" "main" {
  name_prefix = "${data.terraform_remote_state.iaas.environment}/vpn/main"
  vpc_id = "${data.terraform_remote_state.iaas.vpc_id}"

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "${data.terraform_remote_state.iaas.vpc_cidr}"
    ]
  }

  # create-env

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 6868
    to_port = 6868
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_security_group" "ssh" {
  name_prefix = "${data.terraform_remote_state.iaas.environment}/vpn/ssh"
  vpc_id = "${data.terraform_remote_state.iaas.vpc_id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "${var.vpn_cidr}"
    ]
  }
}
