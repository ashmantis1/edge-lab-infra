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

variable "proxmox_tls_insecure" {
    description = "Proxmox API user"
    default = true
    type = bool 
}

variable "proxmox_datastore_id" {
    description = "Name/ID of proxmox datastore"
    type = string
}

variable "vm_templates" {
    description = "ID of vm template to clone"
    type = list(number)
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

variable "search_domain" {
    description = "DNS search domain to use for the cluster"
    type = string 
}

variable "nodes" {
    description = "List of master nodes"
    type = list(string)
}
variable "node_count" {
    description = "Number of master nodes"
    type = number 
}
variable "tags" {
    description = "Comma seperated list of tags"
    type = string
}
variable "cpu" {
    description = "Master node CPU cores"
    type = number 
}

variable "memory" {
    description = "Master node RAM in MB"
    type = number 
}

variable "disk_size" {
    description = "Master node disk size in GB"
    type = number 
}

variable "firewall" { 
    description = "Enable firewall on proxmox nic"
    type = bool
    default = false
}

variable "service_name" {
    description = "Service name"
    type = string 
}

variable "storage_pool" {
    description = "Storage pool name"
    type = string 
}

variable "network_gateway" {
    description = "Static network gateway"
    type = string
}

variable "network_subnet" {
    description = "Static network gateway"
    type = string
}

variable "network_mask" {
    description = "Static network gateway"
    type = string
}

variable "network_start_ip" {
    description = "network start ip"
    type = string
}

variable "tag" {
    description = "Vlan tag"
    default = 0
    type = number 
}

variable "bridge" {
    description = "Network bridge"
    type = string
}

variable "description" {
    description = "Description for hosts"
    type = string
}
