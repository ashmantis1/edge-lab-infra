// Proxmox details

variable "proxmox_host" {
    description = "Proxmox host address (ip/domain:port) https will be appended"
    type = string 
}
variable "proxmox_password" {
    description = "Proxmox API password"
    type = string 
    sensitive = true
}
variable "proxmox_user" {
    description = "Proxmox API user"
    type = string 
}

variable "proxmox_datastore_id" {
    description = "Name/ID of proxmox datastore"
    type = string
}

variable "vm_template_id" {
    description = "ID of vm template to clone"
    type = number
}

variable "vm_id" {
    description = "VM ID to use for the master node"
    type = number 
}

variable "vm_user_ssh_key" {
    description = "User to create with cloud init"
    type = string 
}

variable "vm_user" {
    description = "User to create with cloud init"
    type = string 
}

variable "dns_server" {
    description = "DNS server to use for the cluster"
    type = string 
}

variable "master_nodes" {
    description = "List of master nodes"
    type = list(string)
}
variable "master_count" {
    description = "Number of master nodes"
    type = number 
}
variable "master_cpu" {
    description = "Master node CPU cores"
    type = number 
}

variable "master_memory" {
    description = "Master node RAM in MB"
    type = number 
}

variable "disk_size" {
    description = "Master node disk size in GB"
    type = number 
}

//variable "cloud_image" {
//    description = "Cloud image to use for the master nodes"
//    type = string 
//}
