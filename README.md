For bootstrapping a fresh environment...

 * vpn (via [openvpn](https://github.com/dpb587/openvpn-bosh-release))
 * nat (via [networking](https://github.com/cloudfoundry/networking-release))
 * bosh


## Requirements

 * [bosh](https://github.com/cloudfoundry/bosh-cli/releases/tag/v0.0.133) - for deploying VMs (patched)
 * [direnv](https://direnv.net/) - for automatically setting some environment variables
 * [git](https://git-scm.com/) - for cloning this repository
 * [jq](https://stedolan.github.io/jq/) - for transforming some JSON data
 * [openvpn](https://openvpn.net/index.php/open-source.html) (or [Tunnelblick](https://tunnelblick.net/)) - for securely connecting to the environment
 * [terraform](https://www.terraform.io/) - for managing IaaS-specific resources


## Configuration

All configuration and generated credentials will be stored in a `state` directory. For a new environment...

    $ mkdir state
    $ echo 'export iaas=aws' >> state/.envrc
    $ echo 'export BOSH_ENVIRONMENT=my-env-name' >> state/.envrc
    $ ssh-keygen -t rsa -b 2048 -f state/id_rsa -P ''
    $ direnv allow

Store the `state` directory securely - it contains credentials. It is `.gitignore`'d.


### Amazon Web Services

For AWS, ensure the following environment variables are configured...

    $ export AWS_DEFAULT_REGION=
    $ export AWS_ACCESS_KEY_ID=
    $ export AWS_SECRET_ACCESS_KEY=


## Provision

All provisioning commands are idempotent. Provision shared IaaS-specific resources...

    $ provision iaas

 > *AWS*: this provisions a VPC, subnets, security groups, routing tables, IAM user/credential

Provision a **VPN server**...

    $ provision vpn

 > *AWS*: this provisions an EIP and security group.

Once the VPN server is provisioned, create a connection profile and start the VPN connection...

    $ interpolate vpn profile.ovpn.yml --path /profile > state/vpn.ovpn
    $ open state/vpn.ovpn

Provision a **NAT server**...

    $ provision nat

 > *AWS*: this provisions an EIP and security group.

Provision a **BOSH director**...

    $ provision-iaas bosh
    $ provision-env bosh \
      --vars-file <(
        interpolate bosh empty.yml \
          --vars-file iaas_vpn=<( iaas vpn ) \
          --ops-file env/bosh/iaas/$iaas/manifest-vars.yml
      ) \
      --ops-file env/bosh/iaas/aws/manifest-cheaper.yml # aws!

Once the BOSH director is provisioned, connect to the director...

    $ source etc/bosh

Configure the **cloud config**...

    $ bosh -n update-cloud-config \
      <(
        interpolate bosh cloud-config.yml \
          --ops-file env/bosh/iaas/$iaas/cloud-config.yml
      )

Deploy something fun like **concourse**...

    $ cp -r sample/concourse env/concourse
    $ provision concourse


## Maintenance

Fork the repository and create your own deployment and resources in `env`. When you're ready to upgrade the core components like the `nat`, `vpn`, or `director`, merge this repository again and rerun the provisioning commands.


## License

[MIT License](LICENSE)
