variable "appId" {
  description = "Azure Kubernetes Service Cluster service principal"
}

variable "password" {
  description = "Azure Kubernetes Service Cluster password"
}

variable "vnet_address_prefixes" {
  description = "Address prefixes for the bastion subnet"
  default     = "10.13.0.0/16"
}

variable "management_subnet_address_prefix" {
  description = "Management subnet that hosts juphost"
  default     = "10.13.0.0/24"
}

variable "zone_subnet_address_prefix" {
  description = "K8S Nodes and Pods"
  default     = "10.13.0.1/24"
}

variable "zone_name" {
  description = "K8S Nodes and PODs subnet; CNI used"
  default     = "cni-nodesandpods"
}

variable "service_cidr" {
  description = "K8S internal service subnet"
  default     = "10.200.0.0/24"
}

variable "dns_service_ip" {
  description = "K8S internal DNS service subnet"
  default     = "10.200.0.10"
}

variable "admin_username" {
  description = "K8S admin user of bastionhost"
  default     = "PawnedAdmin"

}

/*

extra_admin_username, K8S admin user of jumphost, PawnedAdmin

extra_admin_ssh_crt, K8S public key of admin user

extra_admin_ssh_crt, K8S VMSS / node VM size

extra_sp_client_id, Service Principal / client ID

extra_sp_client_secret, Service Principal / client Secret

*/
