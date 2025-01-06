output "master_ips" {
    value = [for i in proxmox_vm_qemu.freeipa-masters: i.default_ipv4_address]
}
