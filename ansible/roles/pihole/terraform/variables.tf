// DNS managment details

variable "dns_server" {
    description = "DNS server IP address"
    type = string 
}


// Proxmox details

variable "proxmox_datastore_id" {
    description = "Name/ID of proxmox datastore"
    type = string
}

variable "vm_template_id" {
    description = "ID of vm template to clone"
    type = number
}

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

variable "vm_user" {
    description = "User to create with cloud init"
    type = string 
}
variable "vm_user_ssh_key" {
    description = "User to create with cloud init"
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

variable "service_name" {
    description = "Service name"
    type = string 
}

variable "storage_pool" {
    description = "Storage pool name"
    type = string 
}

variable "bridge" {
    description = "Network bridge"
    type = string 
}

variable "tag" {
    description = "Vlan tag"
    default = 0
    type = number 
}

variable "tags" {
    description = "Comma seperated list of tags"
    type = string
}
