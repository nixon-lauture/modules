# modules/vertex-ai/main.tf

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "aiplatform.googleapis.com",
    "notebooks.googleapis.com",
    "compute.googleapis.com",
    "storage.googleapis.com",
    "secretmanager.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ])
  
  service            = each.value
  disable_on_destroy = false
}

# Service Account for Vertex AI Pipeline operations
resource "google_service_account" "vertex_pipeline_sa" {
  account_id   = "${replace(var.project_id, "-", "")}${var.environment}vxpipe"
  display_name = "Vertex AI Pipeline Service Account - ${var.environment}"
  description  = "Service account for Vertex AI Pipeline operations"
}

# Service Account for Vertex AI Training
resource "google_service_account" "vertex_training_sa" {
  account_id   = "${replace(var.project_id, "-", "")}${var.environment}vxtrain"
  display_name = "Vertex AI Training Service Account - ${var.environment}"
  description  = "Service account for Vertex AI Training jobs"
}

# IAM permissions for Pipeline Service Account
resource "google_project_iam_member" "pipeline_sa_permissions" {
  for_each = toset([
    "roles/aiplatform.user",
    "roles/storage.admin",
    "roles/bigquery.admin",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/secretmanager.secretAccessor"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.vertex_pipeline_sa.email}"
}

# IAM permissions for Training Service Account
resource "google_project_iam_member" "training_sa_permissions" {
  for_each = toset([
    "roles/aiplatform.user",
    "roles/storage.objectAdmin",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/secretmanager.secretAccessor"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.vertex_training_sa.email}"
}

# Developer access to Vertex AI
resource "google_project_iam_member" "developer_vertex_access" {
  for_each = toset(var.developer_principals)
  
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = each.value
}

resource "google_project_iam_member" "developer_notebook_access" {
  for_each = toset(var.developer_principals)
  
  project = var.project_id
  role    = "roles/notebooks.admin"
  member  = each.value
}

# Get Vertex AI service agent
data "google_project" "current" {}

locals {
  vertex_service_agent = "service-${data.google_project.current.number}@gcp-sa-aiplatform.iam.gserviceaccount.com"
}

# Grant Vertex AI service agent access to storage buckets
resource "google_storage_bucket_iam_member" "vertex_model_bucket_access" {
  count = var.model_bucket_name != null ? 1 : 0
  
  bucket = var.model_bucket_name
  role   = "roles/storage.admin"
  member = "serviceAccount:${local.vertex_service_agent}"
}

resource "google_storage_bucket_iam_member" "vertex_staging_bucket_access" {
  count = var.staging_bucket_name != null ? 1 : 0
  
  bucket = var.staging_bucket_name
  role   = "roles/storage.admin"
  member = "serviceAccount:${local.vertex_service_agent}"
}

# Vertex AI Dataset
resource "google_vertex_ai_dataset" "datasets" {
  for_each = var.datasets
  
  display_name        = "${var.project_id}-${var.environment}-${each.key}"
  metadata_schema_uri = each.value.metadata_schema_uri
  region              = var.region
  
  labels = merge(var.labels, {
    environment = var.environment
    dataset     = each.key
  })
  
  depends_on = [google_project_service.required_apis]
}

# Vertex AI Model Registry entries
resource "google_vertex_ai_model" "models" {
  for_each = var.models
  
  display_name       = "${var.project_id}-${var.environment}-${each.key}"
  description        = each.value.description
  version_aliases    = each.value.version_aliases
  region             = var.region
  
  labels = merge(var.labels, {
    environment = var.environment
    model       = each.key
  })
  
  depends_on = [google_project_service.required_apis]
}

# Vertex AI Endpoints for model serving
resource "google_vertex_ai_endpoint" "endpoints" {
  for_each = var.endpoints
  
  name         = "${var.project_id}-${var.environment}-${each.key}-endpoint"
  display_name = "${var.project_id}-${var.environment}-${each.key}"
  description  = each.value.description
  location     = var.region
  region       = var.region
  
  labels = merge(var.labels, {
    environment = var.environment
    endpoint    = each.key
  })
  
  depends_on = [google_project_service.required_apis]
}

# Vertex AI Featurestore
resource "google_vertex_ai_featurestore" "featurestore" {
  count = var.create_featurestore ? 1 : 0
  
  name   = "${var.project_id}-${var.environment}-featurestore"
  region = var.region
  
  labels = merge(var.labels, {
    environment = var.environment
  })
  
  online_serving_config {
    fixed_node_count = var.featurestore_config.fixed_node_count
  }
  
  dynamic "encryption_spec" {
    for_each = var.kms_key_name != "" ? [1] : []
    content {
      kms_key_name = var.kms_key_name
    }
  }
  
  depends_on = [google_project_service.required_apis]
}

# Vertex AI Workbench (Jupyter Notebook instance)
resource "google_notebooks_instance" "workbench" {
  count = var.create_workbench ? 1 : 0
  
  name     = "${var.project_id}-${var.environment}-workbench"
  location = var.workbench_config.zone
  
  machine_type = var.workbench_config.machine_type
  
  vm_image {
    project      = var.workbench_config.image_project
    image_family = var.workbench_config.image_family
  }
  
  install_gpu_driver = var.workbench_config.install_gpu_driver
  
  dynamic "accelerator_config" {
    for_each = var.workbench_config.accelerator_type != "" ? [1] : []
    content {
      type  = var.workbench_config.accelerator_type
      count = var.workbench_config.accelerator_count
    }
  }
  
  service_account = google_service_account.vertex_pipeline_sa.email
  service_account_scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/userinfo.email"
  ]
  
  boot_disk_type    = var.workbench_config.boot_disk_type
  boot_disk_size_gb = var.workbench_config.boot_disk_size_gb
  data_disk_type    = var.workbench_config.data_disk_type
  data_disk_size_gb = var.workbench_config.data_disk_size_gb
  
  disk_encryption = var.kms_key_name != "" ? "CMEK" : "GMEK"
  kms_key         = var.kms_key_name
  
  network    = var.workbench_config.network
  subnet     = var.workbench_config.subnet
  
  no_public_ip    = var.workbench_config.no_public_ip
  no_proxy_access = var.workbench_config.no_proxy_access
  
  labels = merge(var.labels, {
    environment = var.environment
    workbench   = "true"
  })
  
  metadata = merge(
    {
      "enable-oslogin" = "TRUE"
    },
    var.workbench_config.metadata
  )
  
  # Post startup script for additional setup
  post_startup_script = var.workbench_config.post_startup_script
  
  depends_on = [
    google_project_service.required_apis,
    google_project_iam_member.pipeline_sa_permissions
  ]
}

# Vertex AI Training Job template (for custom training)
resource "google_vertex_ai_training_pipeline" "training_pipelines" {
  for_each = var.training_pipelines
  
  display_name = "${var.project_id}-${var.environment}-${each.key}-training"
  
  training_task_definition = jsonencode({
    "@type" = "type.googleapis.com/google.cloud.aiplatform.v1.CustomJobSpec"
    job_spec = {
      worker_pool_specs = [{
        machine_spec = {
          machine_type      = each.value.machine_type
          accelerator_type  = each.value.accelerator_type
          accelerator_count = each.value.accelerator_count
        }
        replica_count = each.value.replica_count
        container_spec = {
          image_uri = each.value.container_image_uri
          args      = each.value.args
          env = [
            for k, v in each.value.environment_variables : {
              name  = k
              value = v
            }
          ]
        }
      }]
      service_account = google_service_account.vertex_training_sa.email
      network         = var.workbench_config.network
      base_output_directory = {
        output_uri_prefix = "gs://${var.staging_bucket_name}/training-outputs/${each.key}"
      }
    }
  })
  
  labels = merge(var.labels, {
    environment = var.environment
    pipeline    = each.key
  })
  
  depends_on = [google_project_service.required_apis]
}

# Vertex AI Batch Prediction Jobs
resource "google_vertex_ai_batch_prediction_job" "batch_predictions" {
  for_each = var.batch_prediction_jobs
  
  display_name = "${var.project_id}-${var.environment}-${each.key}-batch-prediction"
  model        = each.value.model_id
  
  input_config {
    instances_format = each.value.input_format
    gcs_source {
      uris = each.value.input_uris
    }
  }
  
  output_config {
    predictions_format = each.value.output_format
    gcs_destination {
      output_uri_prefix = "gs://${var.staging_bucket_name}/batch-predictions/${each.key}"
    }
  }
  
  dedicated_resources {
    machine_spec {
      machine_type      = each.value.machine_type
      accelerator_type  = each.value.accelerator_type
      accelerator_count = each.value.accelerator_count
    }
    starting_replica_count = each.value.starting_replica_count
    max_replica_count     = each.value.max_replica_count
  }
  
  service_account = google_service_account.vertex_pipeline_sa.email
  
  labels = merge(var.labels, {
    environment = var.environment
    batch_job   = each.key
  })
  
  depends_on = [google_project_service.required_apis]
}

# Monitoring for Vertex AI services
resource "google_monitoring_alert_policy" "vertex_training_failures" {
  count = var.enable_monitoring ? 1 : 0
  
  display_name = "${var.project_id}-${var.environment} Vertex AI Training Failures"
  combiner     = "OR"
  enabled      = true
  
  conditions {
    display_name = "Training job failure rate"
    
    condition_threshold {
      filter         = "resource.type=\"aiplatform.googleapis.com/TrainingJob\""
      duration       = "60s"
      comparison     = "COMPARISON_GT"
      threshold_value = 0
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  
  notification_channels = var.notification_channels
  
  alert_strategy {
    auto_close = "86400s"  # 24 hours
  }
}

# Log-based metrics for Vertex AI operations
resource "google_logging_metric" "vertex_operations" {
  for_each = var.enable_monitoring ? toset([
    "training_jobs",
    "batch_predictions",
    "endpoint_predictions"
  ]) : []
  
  name = "${var.project_id}_${var.environment}_vertex_${each.key}"
  filter = "resource.type=\"aiplatform.googleapis.com/${title(each.key)}\""
  
  metric_descriptor {
    metric_kind  = "GAUGE"
    value_type   = "INT64"
    display_name = "Vertex AI ${title(replace(each.key, "_", " "))}"
  }
  
  label_extractors = {
    operation_type = "EXTRACT(labels.operation_type)"
    status         = "EXTRACT(labels.status)"
  }
}
