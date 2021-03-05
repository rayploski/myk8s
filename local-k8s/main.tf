provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "home-k8s"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

variable "host" {
  type = string
}

variable "client_certificate" {
  type = string
}

variable "client_key" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}

resource "kubernetes_namespace" "development" {
  metadata {
    name = "development"
  }
}

