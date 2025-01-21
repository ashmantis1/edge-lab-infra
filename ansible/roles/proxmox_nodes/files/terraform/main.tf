terraform {
  backend "s3" {}
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.1-rc6"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://${ var.proxmox_host }"
  pm_api_token_id = "${ var.proxmox_user }"
  pm_api_token_secret = "${ var.proxmox_password }"
  pm_tls_insecure = "${ var.proxmox_tls_insecure }"
}

resource "proxmox_vm_qemu" "nodes" {
  count = var.node_count
  name = "${var.service_name}${format("%02s", count.index+1)}"
  desc = "${ var.description }"
  tags =  count.index < var.primary_count ? "${ var.service_name },${var.service_name}primary,${ var.tags }" : "${ var.service_name },${ var.service_name}secondary,${ var.tags }"
  target_node = "${var.nodes[count.index]}"

  agent = 1
  onboot = true

  cores = var.cpu
  memory = var.memory

  network {
    id = 0
    firewall = var.firewall
    link_down = false
    model = "e1000"
    bridge = "${ var.bridge }"
    tag = var.tag
  }

  disks {
    ide {
      ide3 {
        cloudinit {
          storage = "${ var.storage_pool }"
        }
      }
    }
    virtio {
      virtio0 {
        disk {
          size = "30G"
          storage = "${ var.storage_pool }"
        }
      }
    }
  }

  nameserver = var.dns_server
  #clone = "fedora41"
  # Cursed but hopefully works
  clone_id = var.vm_templates[count.index]
  os_type = "cloud-init"

  ipconfig0 = "${format("ip=%s/%s,gw=%s",cidrhost("${var.network_subnet}/${var.network_mask}", var.network_start_ip + count.index), var.network_mask, var.network_gateway)}" 

  ssh_user = "${ var.vm_user }"
  sshkeys = <<EOF
  ${ var.vm_user_ssh_key }
  EOF

}
