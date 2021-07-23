variable "host" {
    description = "The address of your kubernetes control plane"
}

variable "client_certificate" {
    description = "Your kubernetes client certificate"
}

variable "client_key" {
    description = "Your kubernetes client key"
}

variable "cluster_ca_certificate" {
    description = "The kubernetes cluster certificate authority" 
}