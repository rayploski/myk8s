resource "kubernetes_config_map" "metallb_ippool" {
  metadata { 
    name = "config"
    namespace = "metallb-system"
  }

  data = {
      config = <<EOF
---
address-pools:
- name: address-pool-1
  protocol: layer2
  addresses:
  - 10.0.2.128/25      
EOF     
  }
}