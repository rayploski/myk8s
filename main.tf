provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "home-k8s"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "kubernetes_namespace" "development" {
  metadata {
    name = "development"
  }
}


module "metallb" {
  source  = "colinwilson/metallb/kubernetes"
  version = "0.1.5"
}

module "metallb_ippool" {
  source = "./metal-lb"
  depends_on = [
    module.metallb
  ]
}


module "pihole" {
  source = "./pihole/terraform/"
  depends_on = [
    module.metallb_ippool
  ]
}
