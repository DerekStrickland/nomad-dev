job "loki" {
  region      = "global"
  datacenters = ["dc1"]


  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  constraint {
    attribute = "$${attr.unique.hostname}"
    value     = "node-client-1"
  }

  group "loki" {
    count = 1

    network {
      mode = "bridge"

      port "loki" {
        static = 3100
        to     = 3100
      }

      port "grpc" {
        to = 9095
      }
    }

    service {
      name = "loki"
      port = "loki"

      connect {
        sidecar_service {}
      }
    }

    task "loki" {
      driver = "docker"

      config {
        image = "grafana/loki:latest"
        args = [
          "--config.file=/etc/loki/config/loki.yml",
        ]

        volumes = [
          "local:/wal",
          "local/config:/etc/loki/config",
        ]
      }

      template {
        data = <<EOH
---
auth_enabled: false
server:
  http_listen_port: {{ env "NOMAD_PORT_loki" }}
ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
    final_sleep: 0s
  chunk_idle_period: 5m
  chunk_retain_period: 30s
schema_config:
  configs:
  - from: 2020-05-15
    store: boltdb
    object_store: filesystem
    schema: v11
    index:
      prefix: index_
      period: 168h
storage_config:
  boltdb:
    directory: /tmp/loki/index
  filesystem:
    directory: /tmp/loki/chunks
limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h
EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config/loki.yml"
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}