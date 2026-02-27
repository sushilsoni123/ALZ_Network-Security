subscription_id="dbbf834e-d172-43ce-9e9b-e698443b0ce8"


dc_rg_name="dc_rg"
dc_cidr_id=["10.7.0.0/16"]
dc_vm_subnet=["10.7.0.0/24"]
dc_region="uksouth"
 ##these sensitive info should be set in environment variable before running terraform apply (export TF_VAR_keyword='Azure!@123')
tag="test"
dc_gateway_subnet=["10.7.1.0/24"]
dc_local_asn=65516
dc_remote_asn=65001
dc_bgp_peer1="10.5.1.4"
dc_bgp_peer2="10.5.1.5"
dc_accepted_prefixes=["10.5.0.0/16", "10.9.0.0/16", "10.10.0.0/16", "10.11.0.0/16"]
bgp_keyword="Azure!@123" ##these sensitive info should be set in environment variable before running terraform apply (export TF_VAR_keyword='Azure!@123')



rhub_rg_name="rhub_rg"
rhub_cidr_id=["10.5.0.0/16"]
rhub_region="northeurope"
rhub_gateway_subnet=["10.5.1.0/24"]
rhub_local_asn=65001
rhub_remote_asn=65516
rhub_bgp_peer1="10.7.1.4"
rhub_bgp_peer2="10.7.1.5"
rhub_accepted_prefixes=["10.7.0.0/16"]
