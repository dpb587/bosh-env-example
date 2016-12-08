data "terraform_remote_state" "iaas" {
  backend = "local"
  config = {
    path = "${path.module}/../../../../state/iaas_iaas.tfstate"
  }
}

variable "private_ip" { default = "10.187.0.6" }
output "private_ip" { value = "${var.private_ip}" }

output "securitygroup" { value = "${aws_security_group.main.id}" }

output "public_ip" { value = "${aws_eip.main.public_ip}" }

resource "aws_eip" "main" {
  vpc      = true
}

resource "aws_security_group" "main" {
  name_prefix = "${data.terraform_remote_state.iaas.environment}/nat/main"
  vpc_id = "${data.terraform_remote_state.iaas.vpc_id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "${data.terraform_remote_state.iaas.private_subnet_cidr}"
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  # create-env

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      # todo from vpn only
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 6868
    to_port = 6868
    protocol = "tcp"
    cidr_blocks = [
      # todo from vpn only
      "0.0.0.0/0"
    ]
  }
}
