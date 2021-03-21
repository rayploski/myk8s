
resource "kubernetes_persistent_volume" "waypoint_data_pv" {
  metadata {
    name = "data"
  }
  spec {
    capacity = {
      storage = "10Gi"
    }
    access_modes       = ["ReadWriteOnce"]
    persistent_volume_source {
      local {
        path = "/data/k8s-pv/waypoint"
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

/*

resource "kubernetes_stateful_set" "waypoint_set" {
  metadata {
    name = "waypoint-server"
    labels = {
      "app" = "waypoint-server"
    }
  }

  spec {
      init_container {
          name = "data-permission-fix"
          image = "busybox:latest"
          imagePullPolicy = "IfNotPresent"
          command = ["/bin/chmod", "-R", "777", "/data"]
          volume_mount {
              name = "data"
              mount_path = "/data"
          }
      }

      container {
          name = "server"
          image = "hashicorp/waypoint:latest"
          imagePullPolicy = "Always"
          command = "waypoint"
          args = [
            " server",
            " run",
            "-accept-tos",
            "-vvv",
            "-db=/data/data.db",
            "-listen-grpc=0.0.0.0:9701",
            "-listen-http=0.0.0.0:9702"
          ]
        port {
            container_port = 9701
            name = "grpc"
        } 
        port {
            container_port = 9702
            name = "http"
        }
        
        liveness_probe {
            tcp_socket {
              port = "grpc"
            }
        }

        liveness_probe {
          http_get {
            path = "/"
            port = "http"
            scheme = "HTTPS"
          }
        }
        
      }
  }


}

/*
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: waypoint-server
  namespace: default
  labels:
    app: waypoint-server
spec:
  selector:
    matchLabels:
      app: waypoint-server
  serviceName: waypoint-server
  template:
    metadata:
      labels:
        app: waypoint-server
    spec:
      imagePullSecrets:
      - name: github
      initContainers:
      - name: data-permission-fix
        image: busybox
        command: ["/bin/chmod","-R","777", "/data"]
        volumeMounts:
        - name: data
          mountPath: /data
      containers:
      - name: server
        image: hashicorp/waypoint:latest
        imagePullPolicy: Always
        command:
        - "waypoint"
        args:
        - server
        - run
        - -accept-tos
        - -vvv
        - -db=/data/data.db
        - -listen-grpc=0.0.0.0:9701
        - -listen-http=0.0.0.0:9702
        ports:
        - containerPort: 9701
          name: grpc
        - containerPort: 9702
          name: http
        livenessProbe:
          tcpSocket:
            port: grpc
        livenessProbe:
          httpGet:
            path: /
            port: http
            scheme: HTTPS
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
        volumeMounts:
        - name: data
          mountPath: /data
      securityContext:
        fsGroup: 1000
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
          */