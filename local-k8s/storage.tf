/*
We want to create a persistent volume for our Jenkins controller pod.
This will prevent us from losing our whole configuration of the Jenkins controller
and our jobs when we reboot our node.
*/
resource "kubernetes_persistent_volume" "local_pv" {
  metadata {
    name = "enceladus-pv"
    labels = {
      type = "local"
      arch = "ARM64"
    }
  }
  spec {
    capacity = {
      storage = "1028Gi"
    }
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "local-storage"
    persistent_volume_source {
      local {
        path = "/data/k8s-pv/"
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
