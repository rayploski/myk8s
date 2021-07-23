resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

resource "kubernetes_storage_class" "vault_storage" {
  metadata {
    name = "vault-storage"
  }
  storage_provisioner = "kubernetes.io/no-provisioner"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
}


resource "kubernetes_persistent_volume" "vault_data_pv" {
  metadata {
    name = "data-vault"
  }
  spec {
    capacity = {
      storage = "10Gi"
    }
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "vault-storage"
    persistent_volume_source {
      local {
        path = "/data/k8s-pv/vault/data"
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


resource "kubernetes_persistent_volume" "vault_audit_pv" {
  metadata {
    name = "data-audit"
  }
  spec {
    capacity = {
      storage = "10Gi"
    }
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "vault-storage"
    persistent_volume_source {
      local {
        path = "/data/k8s-pv/vault/audit"
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

/* To install vault you will need add the HashiCorp vault repo
*
* helm repo add hashicorp https://helm.releases.hashicorp.com
* helm repo update
* helm search repo vault --versions
*/
resource "helm_release" "vault_consul_helm" {
  name      = "consul"
  chart     = "hashicorp/consul"
  repository = "https://helm.releases.hashicorp.com"
  namespace = "vault"
  values = [
    "${file("../modules/vault/consul-values.yaml")}"
  ]

}


/* To install vault you will need add the HashiCorp vault repo
*
* helm repo add hashicorp https://helm.releases.hashicorp.com
* helm repo update
* helm search repo vault --versions
*/

resource "helm_release" "vault_helm" {
  name      = "vault"
  chart     = "hashicorp/vault"
  namespace = "vault"
  values = [
    "${file("../modules/vault/vault-values.yaml")}"
  ]
  depends_on = [helm_release.vault_consul_helm, ]
}
