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
    namespace = "${kubernetes_namespace.jenkins.metadata.0.name}"
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
    namespace = "${kubernetes_namespace.jenkins.metadata.0.name}"
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
    namespace = "${kubernetes_namespace.jenkins.metadata.0.name}"
  }
}

# helm repo add jenkinsci https://charts.jenkins.io
# helm repo update
resource "helm_release" "jenkins_helm" {
  name      = "jenkins"
  chart     = "jenkinsci/jenkins"
  namespace = "${kubernetes_namespace.jenkins.metadata.0.name}"
  values = [
    "${file("../modules/jenkins/jenkins-values.yaml")}"
  ]

  depends_on = [kubernetes_cluster_role_binding.jenkins_crb]
}

/*
Release "jenkins" has been upgraded. Happy Helming!
NAME: jenkins
LAST DEPLOYED: Sun Mar 14 09:53:38 2021
NAMESPACE: jenkins
STATUS: deployed
REVISION: 2
NOTES:
1. Get your 'admin' user password by running:
  kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/chart-admin-password && echo
2. Get the Jenkins URL to visit by running these commands in the same shell:
  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        You can watch the status of by running 'kubectl get svc --namespace jenkins -w jenkins'
  export SERVICE_IP=$(kubectl get svc --namespace jenkins jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  echo http://$SERVICE_IP:80/login

3. Login with the password from step 1 and the username: admin
4. Configure security realm and authorization strategy
5. Use Jenkins Configuration as Code by specifying configScripts in your values.yaml file, see documentation: http:///configuration-as-code and examples: https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos

For more information on running Jenkins on Kubernetes, visit:
https://cloud.google.com/solutions/jenkins-on-container-engine

For more information about Jenkins Configuration as Code, visit:
https://jenkins.io/projects/jcasc/


NOTE: Consider using a custom image with pre-installed plugins
*/
