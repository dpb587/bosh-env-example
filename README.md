For bootstrapping a fresh environment using [terraform](https://www.terraform.io/) which includes...

 * vpn (via [openvpn](https://github.com/dpb587/openvpn-bosh-release))
 * nat (via [networking](https://github.com/cloudfoundry/networking-release))
 * bosh

Requires [patched](https://github.com/cloudfoundry/bosh-cli/pull/58.patch) [bosh](https://github.com/cloudfoundry/bosh-cli/releases/tag/v0.0.123), terraform, direnv.

## Setup

Create the `state` directory where all state will live for your environment. Also create a new SSH key. Also set any IaaS-specific variables that Terraform will need (e.g. `AWS_DEFAULT_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`).

    mkdir state
    echo 'export iaas=aws' >> state/.envrc
    echo 'export BOSH_ENVIRONMENT=my-env-name' >> state/.envrc
    ssh-keygen -t rsa -b 2048 -f state/id_rsa -P ''
    direnv allow

Create the shared IaaS resources. For AWS it will be creating a new VPC, subnets, security groups, and an IAM user.

    terraform apply -state=state/iaas.tfstate env/iaas/$iaas

Create a standalone VPN server. Provision the VPN-specific Terraform resources to ensure an IP and security group are available, then deploy the server.

    terraform apply -state=state/iaas_vpn.tfstate env/vpn/iaas/$iaas
    bosh create-env --vars-store state/vpn-vars.yml --vars-file <( tfstate iaas ) --vars-file <( tfstate iaas_vpn ) --ops-file env/vpn/iaas/$iaas/manifest.yml --state state/vpn.json env/vpn/manifest.yml

Once the VPN server is running, generate a connection profile and start the VPN connection.

    bosh interpolate --vars-file state/vpn-vars.yml --vars-file <( tfstate iaas ) --vars-file <( tfstate iaas_vpn ) --path /profile env/vpn/profile.ovpn.yml > state/vpn.ovpn
    open state/vpn.ovpn

Create a NAT VM - first Terraform resources then the server.

    terraform apply -state=state/iaas_nat.tfstate env/nat/iaas/$iaas
    bosh create-env --vars-store state/nat-vars.yml --vars-file <( tfstate iaas ) --vars-file <( tfstate iaas_nat ) --ops-file env/nat/iaas/$iaas/manifest.yml --state state/nat.json env/nat/manifest.yml

Next deploy BOSH - first Terraform resources then the server.

    terraform apply -state=state/iaas_bosh.tfstate env/bosh/iaas/$iaas
    bosh create-env --vars-store state/bosh-vars.yml --vars-file <( tfstate iaas ) --vars-file <( tfstate iaas_bosh ) --ops-file env/bosh/iaas/$iaas/manifest.yml --vars-file <( bosh interpolate --vars-file <( tfstate iaas ) --vars-file <( tfstate iaas_vpn ) --vars-file <( tfstate iaas_bosh ) --ops-file env/bosh/iaas/$iaas/vars.yml <( echo '{}' ) ) --state state/bosh.json env/bosh/manifest.yml

Login to BOSH.

    export BOSH_USER=admin
    export BOSH_PASSWORD="$( bosh interpolate --path /admin_password state/bosh-vars.yml )"
    bosh --ca-cert "$( bosh interpolate --path /default_ca/certificate state/bosh-vars.yml )" -e "$( bosh interpolate --path /iaas_bosh/private_ip <( tfstate iaas_bosh ) )" alias-env $BOSH_ENVIRONMENT

Deploy something.

    $ bosh upload-release http://bosh.io/d/github.com/concourse/concourse?v=2.5.0
    ...
