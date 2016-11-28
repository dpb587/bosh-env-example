# env

    $ tfstate() { terraform output -state="state/$1.tfstate" -json | jq --arg n "$1" '{($n):(to_entries|map({"key":.key,"value":.value.value})|from_entries)}' ; }
    $ ssh-keygen -t rsa -b 2048 -f state/id_rsa -P ''

    # iaas
    $ terraform apply -state=state/iaas.tfstate iaas/aws

    # vpn
    $ terraform apply -state=state/iaas_vpn.tfstate vpn/iaas/aws
    $ bosh create-env --vars-store state/vpn-vars.yml --vars-file <( tfstate iaas ) --vars-file <( tfstate iaas_vpn ) --ops-file vpn/iaas/aws/manifest.yml --state state/vpn.json vpn/manifest.yml
    $ bosh interpolate --vars-file state/vpn-vars.yml --vars-file <( tfstate iaas ) --vars-file <( tfstate iaas_vpn ) --path /profile vpn/profile.ovpn.yml > state/$BOSH_ENVIRONMENT.ovpn
    $ open state/$BOSH_ENVIRONMENT.ovpn

    $ nat
    $ terraform apply -state=state/iaas_nat.tfstate nat/iaas/aws
    $ bosh create-env --vars-store state/nat-vars.yml --vars-file <( tfstate iaas ) --vars-file <( tfstate iaas_nat ) --ops-file nat/iaas/aws/manifest.yml --state state/nat.json nat/manifest.yml
