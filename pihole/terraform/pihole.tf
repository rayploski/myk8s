resource "kubernetes_namespace" "pihole_ns" {
  metadata {
    name = "pihole"
  }
}

/*
We want to create a persistent volume for our DNSMasq service.
This will prevent us from losing our whole configuration of the service
when we reboot our node.
*/
resource "kubernetes_persistent_volume" "dnsmasq_pv" {
  metadata {
    name = "dnsmasq-pv"
    labels = {
      type = "local"
      arch = "ARM64"
    }
  }
  spec {
    capacity = {
      storage = "4Gi"
    }
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "local-storage"
    persistent_volume_source {
      local {
        path = "/data/k8s-pv/dnsmasq"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["enceladus"]
          }
        }
      }
    }
  }
}


resource "kubernetes_persistent_volume_claim" "dnsmasq_pvc" {
  metadata {
    name = "dnsmasq-pvc"
    labels = {
      app       = "pihole"
      component = "dnsmasq-pvc"
      type      = "local"
    }
    namespace = "pihole"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "4Gi"
      }
    }

    storage_class_name = "local-storage"
    volume_name        = "dnsmasq-pv"
  }
}

/*
We want to create a persistent volume for our PiHole service.
This will prevent us from losing our whole configuration of the service
when we reboot our node.
*/
resource "kubernetes_persistent_volume" "pihole_pv" {
  metadata {
    name = "pihole-pv"
    labels = {
      type = "local"
      arch = "ARM64"
    }
  }
  spec {
    capacity = {
      storage = "4Gi"
    }
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "local-storage"
    persistent_volume_source {
      local {
        path = "/data/k8s-pv/pihole"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["enceladus"]
          }
        }
      }
    }
  }
}




resource "kubernetes_persistent_volume_claim" "pihole_pvc" {
  metadata {
    name = "pihole-data-pvc"
    labels = {
      app  = "pihole"
      type = "local"
    }
    namespace = "pihole"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "2Gi"
      }
    }

    storage_class_name = "local-storage"
    volume_name        = "pihole-pv"
  }
}




resource "helm_release" "pihole_helm" {
  name      = "pihole"
  chart     = "../helm/"
  namespace = "pihole"
  values = [
    "${file("pihole-values.yml")}"
  ]

}
