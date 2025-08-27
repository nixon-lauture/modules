# modules/cloud-run/main.tf

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "compute.googleapis.com",
    "vpcaccess.googleapis.com",
    "secretmanager.googleapis.com",
    "iamcredentials.googleapis.com"
  ])
  
  service            = each.value
  disable_on_destroy = false
}

# Service Account for Cloud Run services
resource "google_service_account" "cloud_run_sa" {
  account_id   = "${replace(var.project_id, "-", "")}${var.environment}cr"
  display_name = "Cloud Run Service Account - ${var.environment}"
  description  = "Service account for Cloud Run services in ${var.environment}"
}

# IAM bindings for Cloud Run service account
resource "google_project_iam_member" "cloud_run_permissions" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
    "roles/storage.objectViewer",
    "roles/pubsub.publisher",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Cloud Run services
resource "google_cloud_run_v2_service" "services" {
  for_each = var.services
  
  name     = "${var.project_id}-${var.environment}-${each.key}"
  location = var.region
  
  deletion_protection = var.deletion_protection
  
  template {
    # Scaling configuration
    scaling {
      min_instance_count = each.value.min_instances
      max_instance_count = each.value.max_instances
    }
    
    # Service account
    service_account = google_service_account.cloud_run_sa.email
    
    # Timeout
    timeout = "${each.value.timeout_seconds}s"
    
    # VPC access
    dynamic "vpc_access" {
      for_each = var.vpc_connector_name != "" ? [1] : []
      content {
        connector = var.vpc_connector_name
        egress    = "PRIVATE_RANGES_ONLY"
      }
    }
    
    containers {
      name  = each.key
      image = each.value.image
      
      # Ports
      ports {
        name           = "http1"
        container_port = each.value.port
      }
      
      # Resource limits and requests
      resources {
        limits = {
          cpu    = each.value.cpu
          memory = each.value.memory
        }
        cpu_idle          = each.value.cpu_idle
        startup_cpu_boost = each.value.startup_cpu_boost
      }
      
      # Environment variables
      dynamic "env" {
        for_each = merge(
          {
            ENVIRONMENT = var.environment
            PROJECT_ID  = var.project_id
            REGION      = var.region
          },
          each.value.environment_variables
        )
        content {
          name  = env.key
          value = env.value
        }
      }
      
      # Secret environment variables
      dynamic "env" {
        for_each = each.value.secrets
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret_name
              version = env.value.version
            }
          }
        }
      }
      
      # Volume mounts
      dynamic "volume_mounts" {
        for_each = lookup(each.value, "volumes", [])
        content {
          name       = volume_mounts.value.name
          mount_path = volume_mounts.value.mount_path
        }
      }
      
      # Startup probe
      dynamic "startup_probe" {
        for_each = lookup(each.value, "startup_probe", null) != null ? [1] : []
        content {
          initial_delay_seconds = lookup(each.value.startup_probe, "initial_delay_seconds", 0)
          timeout_seconds      = lookup(each.value.startup_probe, "timeout_seconds", 1)
          period_seconds       = lookup(each.value.startup_probe, "period_seconds", 10)
          failure_threshold    = lookup(each.value.startup_probe, "failure_threshold", 3)
          
          http_get {
            path = lookup(each.value.startup_probe, "path", "/health")
            port = each.value.port
          }
        }
      }
      
      # Liveness probe
      dynamic "liveness_probe" {
        for_each = lookup(each.value, "liveness_probe", null) != null ? [1] : []
        content {
          initial_delay_seconds = lookup(each.value.liveness_probe, "initial_delay_seconds", 0)
          timeout_seconds      = lookup(each.value.liveness_probe, "timeout_seconds", 1)
          period_seconds       = lookup(each.value.liveness_probe, "period_seconds", 10)
          failure_threshold    = lookup(each.value.liveness_probe, "failure_threshold", 3)
          
          http_get {
            path = lookup(each.value.liveness_probe, "path", "/health")
            port = each.value.port
          }
        }
      }
    }
    
    # Volumes
    dynamic "volumes" {
      for_each = lookup(each.value, "volumes", [])
      content {
        name = volumes.value.name
        secret {
          secret       = volumes.value.secret_name
          default_mode = lookup(volumes.value, "default_mode", 0444)
          
          dynamic "items" {
            for_each = lookup(volumes.value, "items", [])
            content {
              path    = items.value.path
              version = items.value.version
              mode    = lookup(items.value, "mode", 0444)
            }
          }
        }
      }
    }
    
    # Execution environment
    execution_environment = lookup(each.value, "execution_environment", "EXECUTION_ENVIRONMENT_GEN2")
    
    # Session affinity
    session_affinity = lookup(each.value, "session_affinity", false)
  }
  
  # Traffic configuration
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
  
  labels = merge(var.labels, {
    service     = each.key
    environment = var.environment
  })
  
  depends_on = [
    google_project_service.required_apis,
    google_service_account.cloud_run_sa
  ]
}

# IAM policy for service access
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  for_each = {
    for name, config in var.services : name => config
    if config.allow_unauthenticated
  }
  
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.services[each.key].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# IAM policy for authenticated access
resource "google_cloud_run_v2_service_iam_member" "authenticated_access" {
  for_each = flatten([
    for service_name, config in var.services : [
      for member in lookup(config, "authorized_members", []) : {
        service = service_name
        member  = member
      }
    ] if !config.allow_unauthenticated
  ])
  
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.services[each.value.service].name
  role     = "roles/run.invoker"
  member   = each.value.member
}

# Cloud Run domain mappings
resource "google_cloud_run_domain_mapping" "custom_domains" {
  for_each = {
    for name, config in var.services : name => config.custom_domain
    if lookup(config, "custom_domain", "") != ""
  }
  
  location = var.region
  name     = each.value
  
  metadata {
    namespace = var.project_id
    labels = merge(var.labels, {
      service = each.key
    })
  }
  
  spec {
    route_name = google_cloud_run_v2_service.services[each.key].name
  }
}

# Load Balancer for multiple services (optional)
resource "google_compute_region_network_endpoint_group" "cloud_run_neg" {
  for_each = var.create_load_balancer ? var.services : {}
  
  name                  = "${var.project_id}-${var.environment}-${each.key}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  
  cloud_run {
    service = google_cloud_run_v2_service.services[each.key].name
  }
}

resource "google_compute_region_backend_service" "cloud_run_backend" {
  count = var.create_load_balancer ? 1 : 0
  
  name                  = "${var.project_id}-${var.environment}-backend"
  region                = var.region
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  
  dynamic "backend" {
    for_each = var.services
    content {
      group = google_compute_region_network_endpoint_group.cloud_run_neg[backend.key].id
    }
  }
  
  log_config {
    enable = true
  }
}

# Monitoring and alerting
resource "google_monitoring_uptime_check_config" "service_uptime" {
  for_each = var.enable_monitoring ? var.services : {}
  
  display_name = "${var.project_id}-${var.environment}-${each.key}-uptime"
  timeout      = "10s"
  period       = "300s"
  
  http_check {
    path    = lookup(each.value, "health_check_path", "/health")
    port    = "443"
    use_ssl = true
    
    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
    }
  }
  
  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = replace(google_cloud_run_v2_service.services[each.key].uri, "https://", "")
    }
  }
  
  selected_regions = var.monitoring_regions
}

# Alert policy for service errors
resource "google_monitoring_alert_policy" "service_errors" {
  count = var.enable_monitoring ? 1 : 0
  
  display_name = "${var.project_id}-${var.environment} Cloud Run Error Rate"
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Cloud Run service error rate"
    
    condition_threshold {
      filter         = "resource.type=\"cloud_run_revision\" resource.labels.service_name=~\"${var.project_id}-${var.environment}-.*\""
      duration       = "300s"
      comparison     = "COMPARISON_GT"
      threshold_value = var.error_threshold
      
      aggregations {
        alignment_period     = "60s"
        per_series_aligner  = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_MEAN"
        group_by_fields     = ["resource.labels.service_name"]
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "1800s"
  }
}
