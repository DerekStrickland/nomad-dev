job "time-template" {
  datacenters = ["dc1"]

  group "cache" {
    count = 6

    max_client_disconnect = "2m"

    spread {
      attribute = "${node.unique.name}"
      weight    = 100
    }

    network {
      port "db" {
        to = 6379
      }
    }

    task "redis" {
      driver = "docker"

      template {
        data        = "---\nkey: {{ timestamp }}"
        destination = "local/file.yml"
      }

      config {
        image = "redis:3.2"

        ports = ["db"]
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}

