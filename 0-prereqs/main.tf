provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "home-k8s"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}


module "metallb" {
  source  = "colinwilson/metallb/kubernetes"
  version = "0.1.5"
}

module "metallb_ippool" {
  source = "../modules/metal-lb"
  depends_on = [
    module.metallb
  ]
}


module "pihole" {
  source = "../modules/pihole/terraform/"
  depends_on = [
    module.metallb_ippool
  ]
}