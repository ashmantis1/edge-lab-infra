#terraform {
#  cloud {
#    organization = "ashmantis"
#
#    workspaces {
#      name = "hl-freeipa-workspace"
#    }
#  }
#}
module "nodes" {
    source = "./modules/nodes"
    proxmox_host = var.proxmox_host
    proxmox_user = var.proxmox_user
    proxmox_password = var.proxmox_password
    proxmox_datastore_id = var.proxmox_datastore_id
    vm_template_id = var.vm_template_id
    vm_user = var.vm_user
    vm_user_ssh_key = var.vm_user_ssh_key
    vm_id = var.vm_id

    dns_server = var.dns_server

    // vm details
    master_nodes = var.master_nodes
    master_count = var.master_count
    master_cpu = var.master_cpu
    master_memory = var.master_memory
    disk_size = var.disk_size
#    cloud_image = var.cloud_image

}

