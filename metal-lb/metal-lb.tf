resource "kubernetes_namespace" "metallb_ns" {
  metadata {
    name = "metallb-system"
    labels = {
      app = "metallb"
    }
  }

}

resource "kubernetes_pod_security_policy" "controller" {
  metadata {
    name = "controller"
    labels = {
      app = "metallb"
    }
    #        namespace = "metallb-system"
  }
  spec {
    allow_privilege_escalation = false
    #        allowed_capabilities =  []
    #        allowed_flex_volumes =   []
    #       allowed_host_paths =
    #        allowed_proc_mount_types =
    #        allowed_unsafe_sysctls =
    #        default_add_capabilities = []
    default_allow_privilege_escalation = false
    #        forbidden_sysctls =
    fs_group {
      rule = "MustRunAs"
      range {
        min = 1
        max = 65535
      }
    }
    host_ipc     = false
    host_network = false
    host_pid     = false
    #        host_ports =
    privileged                 = false
    read_only_root_filesystem  = true
    required_drop_capabilities = ["ALL"]
    run_as_user {
      rule = "MustRunAs"
      range {
        min = 1
        max = 65535
      }
    }
    #        run_as_group =
    se_linux {
      rule = "RunAsAny"
    }
    supplemental_groups {
      rule = "MustRunAs"
      range {
        min = 1
        max = 65535
      }
    }
    volumes = ["configMap", "secret", "emptyDir"]
  }
}
