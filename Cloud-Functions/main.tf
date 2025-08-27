
# modules/cloud-functions/main.tf

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "eventarc.googleapis.com",
    "run.googleapis.com",
    "pubsub.googleapis.com",
    "storage.googleapis.com"
  ])
  
  service            = each.value
  disable_on_destroy = false
}

# Service Account for Cloud Functions
resource "google_service_account" "cloud_functions_sa" {
  account_id   = "${var.project_id}-cf-sa"
  display_name = "Cloud Functions Service Account"
  description  = "Service account for Cloud Functions execution"
}

# IAM bindings for Cloud Functions service account
resource "google_project_iam_member" "cloud_functions_permissions" {
  for_each = toset([
    "roles/storage.objectViewer",
    "roles/pubsub.publisher",
    "roles/pubsub.subscriber",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/cloudtrace.agent"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_functions_sa.email}"
}

# Storage bucket for Cloud Functions source code
resource "google_storage_bucket" "functions_source_bucket" {
  name     = "${var.project_id}-${var.environment}-functions-source"
  location = var.region
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
  
  labels = var.labels
  
  depends_on = [google_project_service.required_apis]
}

# Storage bucket for function data processing
resource "google_storage_bucket" "functions_data_bucket" {
  count = var.create_data_bucket ? 1 : 0
  
  name     = "${var.project_id}-${var.environment}-functions-data"
  location = var.region
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = false
  }
  
  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }
  
  labels = var.labels
}

# Pub/Sub topic for event-driven functions
resource "google_pubsub_topic" "function_triggers" {
  for_each = {
    for name, config in var.functions : name => config
    if config.trigger_type == "pubsub"
  }
  
  name = "${var.project_id}-${var.environment}-${each.key}-topic"
  
  labels = var.labels
  
  depends_on = [google_project_service.required_apis]
}

# Create ZIP archives for function source code
data "archive_file" "function_sources" {
  for_each = var.functions
  
  type        = "zip"
  output_path = "${path.module}/tmp/${each.key}-source.zip"
  
  source {
    content  = templatefile("${path.module}/functions/${each.key}/main.py", {
      environment = var.environment
      project_id  = var.project_id
    })
    filename = "main.py"
  }
  
  source {
    content  = file("${path.module}/functions/${each.key}/requirements.txt")
    filename = "requirements.txt"
  }
}

# Upload function source code to bucket
resource "google_storage_bucket_object" "function_sources" {
  for_each = var.functions
  
  name   = "${each.key}/${data.archive_file.function_sources[each.key].output_md5}.zip"
  bucket = google_storage_bucket.functions_source_bucket.name
  source = data.archive_file.function_sources[each.key].output_path
  
  depends_on = [data.archive_file.function_sources]
}

# Cloud Functions (Gen 2)
resource "google_cloudfunctions2_function" "functions" {
  for_each = var.functions
  
  name     = "${var.project_id}-${var.environment}-${each.key}"
  location = var.region
  
  description = each.value.description
  
  build_config {
    runtime     = each.value.runtime
    entry_point = each.value.entry_point
    
    environment_variables = merge(
      {
        ENVIRONMENT = var.environment
        PROJECT_ID  = var.project_id
        REGION      = var.region
      },
      each.value.environment_variables
    )
    
    source {
      storage_source {
        bucket = google_storage_bucket.functions_source_bucket.name
        object = google_storage_bucket_object.function_sources[each.key].name
      }
    }
  }
  
  service_config {
    max_instance_count = each.value.max_instances
    min_instance_count = each.value.min_instances
    available_memory   = "${each.value.memory_mb}M"
    timeout_seconds    = each.value.timeout_seconds
    
    environment_variables = merge(
      {
        ENVIRONMENT = var.environment
        PROJECT_ID  = var.project_id
        REGION      = var.region
      },
      each.value.environment_variables
    )
    
    ingress_settings               = each.value.trigger_type == "http" ? "ALLOW_ALL" : "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    service_account_email         = google_service_account.cloud_functions_sa.email
    
    # VPC connector configuration
    dynamic "vpc_connector" {
      for_each = var.vpc_connector_name != "" ? [1
