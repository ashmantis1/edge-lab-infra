terraform {
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
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "freeipa-masters" {
  count = var.master_count
  name = "${var.service_name}${format("%02s", count.index+1)}"
  desc = "Free IPA server - managed by Terraform"
  tags =  count.index == 0 ? "freeipa,freeipamaster" : "freeipa,freeipareplica"
  onboot = true

  target_node = "${var.master_nodes[count.index]}"

#  bootdisk = "virtio0"
  agent = 1

  cores = var.master_cpu
  memory = var.master_memory

  network {
    id = 0
    firewall = false
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
  #clone = "fedora41"
  # Cursed but hopefully works
  clone_id = var.vm_template_id + count.index

  os_type = "cloud-init"

  //  os_network_config = <<EOF
  //  auto eth0
  //  iface eth0 inet dhcp
  //  EOF
  ipconfig0 = "${format("ip=10.110.0.%02s/24,gw=10.110.0.1",10 + count.index)}"

  ssh_user = "${ var.vm_user }"
  sshkeys = <<EOF
  ${ var.vm_user_ssh_key }
  EOF

}
