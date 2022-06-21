job "example" {
  datacenters = ["dc1"]

  group "cache" {

    count = 1

    volume "volume0" {
      type            = "csi"
      source          = "test-volume"
      attachment_mode = "file-system"
      access_mode     = "single-node-reader-only" # alt: "single-node-writer"
      read_only       = true
      #per_alloc       = true
    }

    network {
      port "db" {
        to = 6379
      }
    }

    task "shell" {
      driver = "raw_exec"

      config {
        command = "/bin/sh"
        args = [
          "-c",
          "sleep 300"
        ]
      }
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:7"
        ports = ["db"]
      }

      volume_mount {
        volume      = "volume0"
        destination = "${NOMAD_ALLOC_DIR}/volume0"
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}

