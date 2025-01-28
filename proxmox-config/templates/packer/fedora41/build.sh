# Simple build script to build templates across all proxmox cluster nodes

export BW_SESSION=$(bw unlock --raw)
credential_file="../../credentials/credentials.packer.hcl"

nodes=( "vm01" "vm02" )
template_id_start=9000

for idx in "${!nodes[@]}"
do
  vm_id=$(( $template_id_start+$idx ))
  node=${nodes[$idx]}

  packer build -force -var-file=${credential_file} -var=vm_id=${vm_id} -var=node=${node} packer.pkr.hcl
  sleep 5
done
