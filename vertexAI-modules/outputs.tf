# modules/vertex-ai/outputs.tf

output "pipeline_sa_email" {
  description = "Email of the Vertex AI pipeline service account"
  value       = google_service_account.vertex_pipeline_sa.email
}

output "training_sa_email" {
  description = "Email of the Vertex AI training service account"
  value       = google_service_account.vertex_training_sa.email
}

output "vertex_service_agent" {
  description = "Email of the Vertex AI service agent"
  value       = local.vertex_service_agent
}

output "dataset_ids" {
  description = "Map of dataset names to their IDs"
  value = {
    for name, dataset in google_vertex_ai_dataset.datasets : name => dataset.name
  }
}

output "dataset_details" {
  description = "Detailed information about all datasets"
  value = {
    for name, dataset in google_vertex_ai_dataset.datasets : name => {
      id                  = dataset.name
      display_name        = dataset.display_name
      metadata_schema_uri = dataset.metadata_schema_uri
      region              = dataset.region
      create_time         = dataset.create_time
      update_time         = dataset.update_time
    }
  }
}

output "model_ids" {
  description = "Map of model names to their IDs"
  value = {
    for name, model in google_vertex_ai_model.models : name => model.name
  }
}

output "model_details" {
  description = "Detailed information about all models"
  value = {
    for name, model in google_vertex_ai_model.models : name => {
      id              = model.name
      display_name    = model.display_name
      version_aliases = model.version_aliases
      region          = model.region
      create_time     = model.create_time
      update_time     = model.update_time
    }
  }
}

output "endpoint_ids" {
  description = "Map of endpoint names to their IDs"
  value = {
    for name, endpoint in google_vertex_ai_endpoint.endpoints : name => endpoint.name
  }
}

output "endpoint_details" {
  description = "Detailed information about all endpoints"
  value = {
    for name, endpoint in google_vertex_ai_endpoint.endpoints : name => {
      id           = endpoint.name
      display_name = endpoint.display_name
      region       = endpoint.region
      create_time  = endpoint.create_time
      update_time  = endpoint.update_time
    }
  }
}

output "endpoint_urls" {
  description = "Map of endpoint names to their serving URLs"
  value = {
    for name, endpoint in google_vertex_ai_endpoint.endpoints : name => 
    "https://${var.region}-aiplatform.googleapis.com/v1/${endpoint.name}"
  }
}

output "featurestore_id" {
  description = "ID of the Vertex AI Featurestore"
  value       = var.create_featurestore ? google_vertex_ai_featurestore.featurestore[0].name : null
}

output "featurestore_details" {
  description = "Detailed information about the Featurestore"
  value = var.create_featurestore ? {
    id          = google_vertex_ai_featurestore.featurestore[0].name
    region      = google_vertex_ai_featurestore.featurestore[0].region
    create_time = google_vertex_ai_featurestore.featurestore[0].create_time
    update_time = google_vertex_ai_featurestore.featurestore[0].update_time
  } : null
}

output "workbench_instance_name" {
  description = "Name of the Vertex AI Workbench instance"
  value       = var.create_workbench ? google_notebooks_instance.workbench[0].name : null
}

output "workbench_details" {
  description = "Detailed information about the Workbench instance"
  value = var.create_workbench ? {
    name         = google_notebooks_instance.workbench[0].name
    proxy_uri    = google_notebooks_instance.workbench[0].proxy_uri
    instance_owners = google_notebooks_instance.workbench[0].instance_owners
    service_account = google_notebooks_instance.workbench[0].service_account
    machine_type    = google_notebooks_instance.workbench[0].machine_type
    state          = google_notebooks_instance.workbench[0].state
  } : null
}

output "workbench_url" {
  description = "URL to access the Workbench instance"
  value       = var.create_workbench ? google_notebooks_instance.workbench[0].proxy_uri : null
  sensitive   = true
}

output "training_pipeline_ids" {
  description = "Map of training pipeline names to their IDs"
  value = {
    for name, pipeline in google_vertex_ai_training_pipeline.training_pipelines : name => pipeline.name
  }
}

output "batch_prediction_job_ids" {
  description = "Map of batch prediction job names to their IDs"
  value = {
    for name, job in google_vertex_ai_batch_prediction_job.batch_predictions : name => job.name
  }
}

output "model_bucket_name" {
  description = "Name of the model storage bucket"
  value       = var.model_bucket_name
}

output "staging_bucket_name" {
  description = "Name of the staging bucket"
  value       = var.staging_bucket_name
}

output "monitoring_alert_policy_id" {
  description = "ID of the monitoring alert policy for training failures"
  value       = var.enable_monitoring ? google_monitoring_alert_policy.vertex_training_failures[0].name : null
}

output "log_based_metrics" {
  description = "Map of log-based metric names"
  value = var.enable_monitoring ? {
    for name, metric in google_logging_metric.vertex_operations : name => metric.name
  } : {}
}

output "console_urls" {
  description = "Useful console URLs for Vertex AI resources"
  value = {
    vertex_ai_overview = "https://console.cloud.google.com/vertex-ai?project=${var.project_id}"
    datasets          = "https://console.cloud.google.com/vertex-ai/datasets?project=${var.project_id}"
    models            = "https://console.cloud.google.com/vertex-ai/models?project=${var.project_id}"
    endpoints         = "https://console.cloud.google.com/vertex-ai/endpoints?project=${var.project_id}"
    training          = "https://console.cloud.google.com/vertex-ai/training?project=${var.project_id}"
    pipelines         = "https://console.cloud.google.com/vertex-ai/pipelines?project=${var.project_id}"
    workbench         = "https://console.cloud.google.com/vertex-ai/workbench?project=${var.project_id}"
    featurestore      = "https://console.cloud.google.com/vertex-ai/featurestore?project=${var.project_id}"
  }
}

output "service_account_details" {
  description = "Details of all created service accounts"
  value = {
    pipeline_sa = {
      email       = google_service_account.vertex_pipeline_sa.email
      name        = google_service_account.vertex_pipeline_sa.name
      unique_id   = google_service_account.vertex_pipeline_sa.unique_id
      display_name = google_service_account.vertex_pipeline_sa.display_name
    }
    training_sa = {
      email       = google_service_account.vertex_training_sa.email
      name        = google_service_account.vertex_training_sa.name
      unique_id   = google_service_account.vertex_training_sa.unique_id
      display_name = google_service_account.vertex_training_sa.display_name
    }
  }
}
