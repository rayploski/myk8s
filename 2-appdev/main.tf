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


module "jenkins" {
  source = "../modules/jenkins"
}


module "docker-registry" {
  source = "../modules/docker-registry"

}
