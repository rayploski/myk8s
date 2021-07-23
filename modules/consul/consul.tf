resource "kubernetes_namespace" "consul" {
  metadata {
    name = "consul"
  }
}

resource "kubernetes_storage_class" "consul_storage" {
  metadata {
    name = "consul-storage"
  }
  storage_provisioner = "kubernetes.io/no-provisioner"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
}


resource "kubernetes_persistent_volume" "consul_data_pv" {
  metadata {
    name = "consul-data"
  }
  spec {
    capacity = {
      storage = "10Gi"
    }
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "consul-storage"
    persistent_volume_source {
      local {
        path = "/data/k8s-pv/consul/data"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["jupiter"]
          }
        }
      }
    }
  }

}


resource "kubernetes_persistent_volume" "consul_audit_pv" {
  metadata {
    name = "consul-audit"
  }
  spec {
    capacity = {
      storage = "10Gi"
    }
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "consul-storage"
    persistent_volume_source {
      local {
        path = "/data/k8s-pv/consul/audit"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["jupiter"]
          }
        }
      }
    }
  }

}

/* To install consul you will need add the HashiCorp consul repo
*
* helm repo add hashicorp https://helm.releases.hashicorp.com
* helm repo update
* helm search repo consul --versions
*/
resource "helm_release" "consul_consul_helm" {
  name      = "consul"
  chart     = "consul"
  repository = "https://helm.releases.hashicorp.com"
  namespace = "consul"
  values = [
    "${file("./consul/consul-values.yaml")}"
  ]

}