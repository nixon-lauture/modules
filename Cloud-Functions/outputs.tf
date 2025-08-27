# modules/cloud-functions/outputs.tf

output "function_details" {
  description = "Details of all created Cloud Functions"
  value = {
    for name, func in google_cloudfunctions2_function.functions : name => {
      name            = func.name
      url             = func.service_config[0].uri
      state           = func.state
      update_time     = func.update_time
      environment     = func.service_config[0].environment_variables["ENVIRONMENT"]
    }
  }
}

output "function_urls" {
  description = "Map of function names to their trigger URLs"
  value = {
    for name, func in google_cloudfunctions2_function.functions : name => func.service_config[0].uri
    if var.functions[name].trigger_type == "http"
  }
  sensitive = true
}

output "function_names" {
  description = "List of all Cloud Function names"
  value       = [for func in google_cloudfunctions2_function.functions : func.name]
}

output "service_account_email" {
  description = "Email of the service account used by Cloud Functions"
  value       = google_service_account.cloud_functions_sa.email
}

output "source_bucket_name" {
  description = "Name of the source code bucket"
  value       = google_storage_bucket.functions_source_bucket.name
}

output "source_bucket_url" {
  description = "URL of the source code bucket"
  value       = google_storage_bucket.functions_source_bucket.url
}

output "data_bucket_name" {
  description = "Name of the data processing bucket"
  value       = var.create_data_bucket ? google_storage_bucket.functions_data_bucket[0].name : null
}

output "data_bucket_url" {
  description = "URL of the data processing bucket"
  value       = var.create_data_bucket ? google_storage_bucket.functions_data_bucket[0].url : null
}

output "pubsub_topics" {
  description = "Map of Pub/Sub topic names created for functions"
  value = {
    for name, topic in google_pubsub_topic.function_triggers : name => topic.name
  }
}

output "scheduler_jobs" {
  description = "Map of Cloud Scheduler job names"
  value = {
    for name, job in google_cloud_scheduler_job.scheduled_functions : name => job.name
  }
}

output "function_ids" {
  description = "Map of function names to their IDs"
  value = {
    for name, func in google_cloudfunctions2_function.functions : name => func.id
  }
}

output "monitoring_alert_policy_id" {
  description = "ID of the monitoring alert policy for function errors"
  value       = var.enable_monitoring ? google_monitoring_alert_policy.function_errors[0].name : null
}

output "log_based_metrics" {
  description = "Map of log-based metric names"
  value = {
    for name, metric in google_logging_metric.function_invocations : name => metric.name
  }
}
