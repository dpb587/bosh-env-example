data "terraform_remote_state" "iaas" {
  backend = "local"
  config = {
    path = "${path.module}/../../../state/iaas.tfstate"
  }
}

variable "private_ip" { default = "10.187.16.5" }
output "private_ip" { value = "${var.private_ip}" }

output "securitygroup" { value = "${aws_security_group.main.id}" }

resource "aws_security_group" "main" {
  name_prefix = "${data.terraform_remote_state.iaas.environment}/bosh/main"
  vpc_id = "${data.terraform_remote_state.iaas.vpc_id}"

  ingress {
    from_port = 4222
    to_port = 4222
    protocol = "tcp"
    cidr_blocks = [
      "${aws_subnet.private.cidr_block}"
    ]
  }

  ingress {
    from_port = 25250
    to_port = 25250
    protocol = "tcp"
    cidr_blocks = [
      "${aws_subnet.private.cidr_block}"
    ]
  }

  ingress {
    from_port = 25555
    to_port = 25555
    protocol = "tcp"
    cidr_blocks = [
      "${aws_subnet.private.cidr_block}"
    ]
  }

  ingress {
    from_port = 25777
    to_port = 25777
    protocol = "tcp"
    cidr_blocks = [
      "${aws_subnet.private.cidr_block}"
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
      "${aws_subnet.private.cidr_block}"
    ]
  }

  ingress {
    from_port = 6868
    to_port = 6868
    protocol = "tcp"
    cidr_blocks = [
      # todo from vpn only
      "${aws_subnet.private.cidr_block}"
    ]
  }
}
