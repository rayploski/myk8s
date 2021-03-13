resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
  }
}

/*
We want to create a persistent volume for our Jenkins controller pod.
This will prevent us from losing our whole configuration of the Jenkins controller
and our jobs when we reboot our node.
*/
resource "kubernetes_persistent_volume" "jenkins_pv" {
  metadata {
    name = "jenkins-pv"
    labels = {
      type = "local"
    }
  }
  spec {
    capacity = {
      storage = "50Gi"
    }
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "local-storage"
    persistent_volume_source {
      local {
        path = "/data/k8s-pv/jenkins"
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

resource "kubernetes_persistent_volume_claim" "jenkins_pvc" {
  metadata {
    name      = "jenkins-pvc"
    namespace = "jenkins"
    labels = {
      type = "local"
    }
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "48Gi"
      }
    }
    storage_class_name = "local-storage"
    volume_name        = kubernetes_persistent_volume.jenkins_pv.metadata.0.name
  }
}

resource "kubernetes_service_account" "jenkins_sa" {
  metadata {
    name      = "jenkins"
    namespace = "jenkins"
  }
}


/* Create a ClusterRole for Jenkins */
resource "kubernetes_cluster_role" "jenkins_cr" {
  metadata {
    name = "jenkins"
    annotations = {
      "rbac.authorization.kubernetes.io/autoupdate" = "true"
    }
    labels = {
      "kubernetes.io/bootstrapping" = "rbac-defaults"
    }
  }

  /* Give Jenkins a very large swath of privileges within the jenkins namespace */
  rule {
    api_groups = ["*"]
    resources = [
      "configmaps",
      "cronjobs",
      "daemonsets",
      "deployments",
      "deployments/scale",
      "endpoints",
      "events",
      "jobs",
      "namespaces",
      "persistentvolumes",
      "persistentvolumeclaims",
      "poddisruptionbudget",
      "podtemplates",
      "pods",
      "pods/exec",
      "pods/log",
      "podsecuritypolicies",
      "podsreset",
      "replicasets",
      "replicationcontrollers",
      "secrets",
      "services",
      "statefulsets"
    ]

    verbs = [
      "create",
      "get",
      "watch",
      "delete",
      "list",
      "patch",
      "update"
    ]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs = [
      "get",
      "list",
      "watch",
      "update"
    ]
  }
}

/*
A role binding grants the permissions defined in a role to a user or set of users.
It holds a list of subjects (users, groups, or service accounts), and a reference to the role
being granted.

A RoleBinding may reference any Role in the same namespace. Alternatively, a RoleBinding can
reference a ClusterRole and bind that ClusterRole to the namespace of the RoleBinding.
To bind a ClusterRole to all the namespaces in our cluster, we use a ClusterRoleBinding.
*/
resource "kubernetes_cluster_role_binding" "jenkins_crb" {
  metadata {
    name = "jenkins"
    annotations = {
      "rbac.authorization.kubernetes.io/autoupdate" = "true"
    }
    labels = {
      "kubernetes.io/bootstrapping" = "rbac-defaults"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "jenkins"
  }

  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "system:serviceaccounts:jenkins"
    namespace = "jenkins"
  }
}

resource "helm_release" "jenkins_helm" {
  name      = "jenkins"
  chart     = "jenkinsci/jenkins"
  namespace = "jenkins"
  values = [
    "${file("jenkins-values.yaml")}"
  ]

  depends_on = [kubernetes_cluster_role_binding.jenkins_crb]
}
