resource "kubernetes_namespace" "registry_ns" {
  metadata {
    name = "registry"
  }
}

resource "kubernetes_storage_class" "registry_storage" {
  metadata {
    name = "registry-storage"
  }
  storage_provisioner = "kubernetes.io/no-provisioner"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
}


resource "kubernetes_persistent_volume" "registry_pv" {
  metadata {
    name = "registry"
  }
  spec {
    capacity = {
      storage = "10Gi"
    }
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "local-storage"
    persistent_volume_source {
      local {
        path = "/data/k8s-pv/registry/repository"
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

resource "kubernetes_persistent_volume_claim" "registry_pvc" {
  metadata {
    name = "registry-pvc"
    labels = {
      app  = "docker-registry"
      type = "local"
    }
    #    namespace = "registry"  TODO:  Move this out of the default namespace after 
    #    namespace = "${kubernetes_namespace.registry_ns.metadata.0.name}"
    #    generating the certificate and htpasswd locally.
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    storage_class_name = "local-storage"
#    volume_name = "${kubernetes_persistent_volume.registry_pv.metadata.0.name}"
  }

}

resource "kubernetes_pod" "registry_pod" {
  metadata {
    name = "docker-registry-pod"
    labels = {
      app  = "registry"
      type = "local"
    }
    #    namespace = "${kubernetes_namespace.registry_ns.metadata.0.name}"
  }
  spec {
    container {
      image = "registry:2.6.2"
      name  = "registry"
      volume_mount {
        name       = "repo-vol"
        mount_path = "/var/lib/registry"
      }
      volume_mount {
        name       = "certs-vol"
        mount_path = "/certs"
        read_only  = true
      }
      volume_mount {
        name       = "auth-vol"
        mount_path = "/auth"
        read_only  = true
      }
      env {
        name  = "REGISTRY_AUTH"
        value = "htpasswd"
      }
      env {
        name  = "REGISTRY_AUTH_HTPASSWD_REALM"
        value = "Registry Realm"
      }
      env {
        name  = "REGISTRY_AUTH_HTPASSWD_PATH"
        value = "/auth/htpasswd"
      }
      env {
        name  = "REGISTRY_HTTP_TLS_CERTIFICATE"
        value = "/certs/tls.crt"
      }
      env {
        name  = "REGISTRY_HTTP_TLS_KEY"
        value = "/certs/tls.key"
      }
    }
    volume {
      name = "repo-vol"
      persistent_volume_claim {
    #    claim_name = "registry-pvc"
        claim_name = "${kubernetes_persistent_volume_claim.registry_pvc.metadata.0.name}"
      }
    }
    volume {
      name = "certs-vol"
      secret {
        secret_name = "certs-secret"
      }
    }
    volume {
      name = "auth-vol"
      secret {
        secret_name = "auth-secret"
      }
    }
  }
}

resource "kubernetes_service" "registry_svc" {
  metadata {
    name = "docker-registry"
    labels = {
      app  = "docker-registry"
      type = "local"
    }
    #    namespace = "${kubernetes_namespace.registry_ns.metadata.0.name}"
  }
  spec {
    selector = {
      "app" = "registry"
    }
    port {
      port        = "5000"
      target_port = "5000"
    }
    type = "LoadBalancer"
  }
}


/* To install consul you will need add the HashiCorp consul repo
*
* helm repo add hashicorp https://helm.releases.hashicorp.com
* helm repo update
* helm search repo consul --versions
resource "helm_release" "consul_consul_helm" {
  name      = "consul"
  chart     = "hashicorp/consul"
  namespace = "consul"
  values = [
    "${file("./consul/consul-values.yaml")}"
  ]

}
*/
