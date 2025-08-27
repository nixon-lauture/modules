# Enable required APIs
resource "google_project_service" "cloudfunctions_api" {
  service            = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild_api" {
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager_api" {
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

# Storage bucket for function source code
resource "google_storage_bucket" "function_source" {
  name     = "${var.project_id}-${var.environment}-function-source"
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
  
  labels = var.common_labels
}

# Upload function source to bucket
resource "google_storage_bucket_object" "api_processor_source" {
  name   = "api_processor-${data.archive_file.api_processor_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.api_processor_zip.output_path
  
  depends_on = [data.archive_file.api_processor_zip]
}

resource "google_storage_bucket_object" "data_processor_source" {
  name   = "data_processor-${data.archive_file.data_processor_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.data_processor_zip.output_path
  
  depends_on = [data.archive_file.data_processor_zip]
}

# Service Account for Cloud Functions
resource "google_service_account" "cloud_function" {
  account_id   = "${var.project_name}-${var.environment}-cf"
  display_name = "Cloud Functions Service Account"
  description  = "Service account for Cloud Functions"
}

# IAM roles for Cloud Function service account
resource "google_project_iam_member" "cloud_function_invoker" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_function.email}"
}

resource "google_project_iam_member" "cloud_function_storage" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.cloud_function.email}"
}

# API Processor Cloud Function (HTTP Trigger)
resource "google_cloudfunctions_function" "api_processor" {
  name        = "${var.project_name}-${var.environment}-api-processor"
  description = "API processing function"
  runtime     = "python39"
  region      = var.region
  
  available_memory_mb   = 256
  timeout               = 60
  entry_point          = "main"
  service_account_email = google_service_account.cloud_function.email
  
  source_archive_bucket = google_storage_bucket.function_source.name
  source_archive_object = google_storage_bucket_object.api_processor_source.name
  
  trigger {
    https_trigger {
      security_level = "SECURE_ALWAYS"
    }
  }
  
  environment_variables = {
    ENVIRONMENT = var.environment
    PROJECT_ID  = var.project_id
    REGION      = var.region
  }
  
  labels = var.common_labels
  
  depends_on = [
    google_project_service.cloudfunctions_api,
    google_storage_bucket_object.api_processor_source
  ]
}

# Data Processor Cloud Function (Cloud Storage Trigger)
resource "google_cloudfunctions_function" "data_processor" {
  name        = "${var.project_name}-${var.environment}-data-processor"
  description = "Data processing function triggered by Cloud Storage"
  runtime     = "python39"
  region      = var.region
  
  available_memory_mb   = 512
  timeout               = 300
  entry_point          = "main"
  service_account_email = google_service_account.cloud_function.email
  
  source_archive_bucket = google_storage_bucket.function_source.name
  source_archive_object = google_storage_bucket_object.data_processor_source.name
  
  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.data_input.name
  }
  
  environment_variables = {
    ENVIRONMENT = var.environment
    PROJECT_ID  = var.project_id
    REGION      = var.region
    OUTPUT_BUCKET = google_storage_bucket.data_output.name
  }
  
  labels = var.common_labels
  
  depends_on = [
    google_project_service.cloudfunctions_api,
    google_storage_bucket_object.data_processor_source
  ]
}

# Scheduler Job Cloud Function (Pub/Sub Trigger)
resource "google_cloudfunctions_function" "scheduler_processor" {
  name        = "${var.project_name}-${var.environment}-scheduler-processor"
  description = "Function triggered by Cloud Scheduler"
  runtime     = "python39"
  region      = var.region
  
  available_memory_mb   = 256
  timeout               = 60
  entry_point          = "main"
  service_account_email = google_service_account.cloud_function.email
  
  source_archive_bucket = google_storage_bucket.function_source.name
  source_archive_object = google_storage_bucket_object.api_processor_source.name
  
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.scheduler_topic.name
  }
  
  environment_variables = {
    ENVIRONMENT = var.environment
    PROJECT_ID  = var.project_id
    REGION      = var.region
  }
  
  labels = var.common_labels
  
  depends_on = [
    google_project_service.cloudfunctions_api
  ]
}

# IAM for HTTP Cloud Function (public access)
resource "google_cloudfunctions_function_iam_member" "api_processor_invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.api_processor.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}

# Storage buckets for data processing
resource "google_storage_bucket" "data_input" {
  name     = "${var.project_id}-${var.environment}-data-input"
  location = var.region
  
  uniform_bucket_level_access = true
  
  labels = var.common_labels
}

resource "google_storage_bucket" "data_output" {
  name     = "${var.project_id}-${var.environment}-data-output"
  location = var.region
  
  uniform_bucket_level_access = true
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
  
  labels = var.common_labels
}

# Pub/Sub topic for scheduler
resource "google_pubsub_topic" "scheduler_topic" {
  name = "${var.project_name}-${var.environment}-scheduler-topic"
  
  labels = var.common_labels
}

# Cloud Scheduler job
resource "google_cloud_scheduler_job" "data_processing_job" {
  name             = "${var.project_name}-${var.environment}-data-processing"
  description      = "Trigger data processing function"
  schedule         = "0 */6 * * *"  # Every 6 hours
  time_zone        = "UTC"
  attempt_deadline = "320s"
  
  pubsub_target {
    topic_name = google_pubsub_topic.scheduler_topic.id
    data       = base64encode(jsonencode({
      action = "process_data"
      timestamp = "scheduled"
    }))
  }
  
  retry_config {
    retry_count = 3
  }
  
  depends_on = [google_project_service.cloudscheduler_api]
}

# Enable Cloud Scheduler API
resource "google_project_service" "cloudscheduler_api" {
  service            = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}

# VPC Connector for private network access (if needed)
resource "google_vpc_access_connector" "main" {
  count         = var.enable_vpc_connector ? 1 : 0
  name          = "${var.project_name}-${var.environment}-vpc-connector"
  ip_cidr_range = "10.8.0.0/28"
  network       = var.vpc_network
  region        = var.region
  
  depends_on = [google_project_service.vpcaccess_api]
}

# Enable VPC Access API
resource "google_project_service" "vpcaccess_api" {
  count              = var.enable_vpc_connector ? 1 : 0
  service            = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}
