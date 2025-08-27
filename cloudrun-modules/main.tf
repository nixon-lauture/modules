
resource "google_cloud_run_v2_service" "default" {
  name         = "cloudrun-service"
  location     = "us-central1"
  launch_stage = "BETA"
  ingress      = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "gcr.io/${var.project_id}/${var.repo_name}:latest"
      resources {
        limits = {
          cpu    = "2"
          memory = "1024Mi"
        }
      }
      ports {
        container_port = 8080
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }

      env {
        name  = "DB_USER"
        value = data.google_secret_manager_secret_version.db_user.secret_data
      }
      env {
        name  = "DB_PASS"
        value = data.google_secret_manager_secret_version.db_pass.secret_data
      }
      env {
        name  = "DB_NAME"
        value = data.google_secret_manager_secret_version.db_name.secret_data
      }
      env {
        name  = "DB_HOST"
        value = var.db_instance_ip_address
      }
      env {
        name  = "DB_PORT"
        value = "5432"
      }
      env {
        name  = "GITHUB_ACCESS_TOKEN"
        value = data.google_secret_manager_secret_version.github_token.secret_data
      }
      env {
        name  = "SECRET_KEY_ACCESS_API"
        value = data.google_secret_manager_secret_version.secret_key_access_api.secret_data
      }


    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [var.cloud_sql_connection_name]
      }
    }

    vpc_access {
      egress = "ALL_TRAFFIC"

      network_interfaces {
        network    = var.network_id
        subnetwork = var.subnetwork_id
        tags       = ["cloud-run-service"]
      }
    }
  }
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

}

resource "google_cloud_run_service_iam_member" "public_invoker" {
  location = "us-central1"
  service  = google_cloud_run_v2_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
