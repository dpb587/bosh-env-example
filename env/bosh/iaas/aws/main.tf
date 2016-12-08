data "terraform_remote_state" "iaas" {
  backend = "local"
  config = {
    path = "${path.module}/../../../../state/iaas_iaas.tfstate"
  }
}

data "terraform_remote_state" "iaas_vpn" {
  backend = "local"
  config = {
    path = "${path.module}/../../../../state/iaas_vpn.tfstate"
  }
}

variable "private_ip" { default = "10.187.16.5" }
output "private_ip" { value = "${var.private_ip}" }

output "director_securitygroup" { value = "${aws_security_group.director.id}" }

resource "aws_security_group" "director" {
  name_prefix = "${data.terraform_remote_state.iaas.environment}/bosh/main"
  vpc_id = "${data.terraform_remote_state.iaas.vpc_id}"

  ingress {
    from_port = 4222
    to_port = 4222
    protocol = "tcp"
    cidr_blocks = [
      "${data.terraform_remote_state.iaas.private_subnet_cidr}"
    ]
  }

  ingress {
    from_port = 25250
    to_port = 25250
    protocol = "tcp"
    cidr_blocks = [
      "${data.terraform_remote_state.iaas.private_subnet_cidr}"
    ]
  }

  ingress {
    from_port = 25555
    to_port = 25555
    protocol = "tcp"
    cidr_blocks = [
      "${data.terraform_remote_state.iaas.private_subnet_cidr}"
    ]
  }

  ingress {
    from_port = 25777
    to_port = 25777
    protocol = "tcp"
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
      "${data.terraform_remote_state.iaas_vpn.vpn_cidr}"
    ]
  }

  ingress {
    from_port = 6868
    to_port = 6868
    protocol = "tcp"
    cidr_blocks = [
      "${data.terraform_remote_state.iaas_vpn.vpn_cidr}"
    ]
  }
}
