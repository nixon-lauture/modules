# env/dev/outputs.tf - Development Environment Outputs

# VPC Network Outputs
output "vpc_network_name" {
  description = "Name of the development VPC network"
  value       = module.vpc_network.vpc_name
}

output "vpc_network_id" {
  description = "ID of the development VPC network"
  value       = module.vpc_network.vpc_id
}

output "vpc_self_link" {
  description = "Self-link of the development VPC network"
  value       = module.vpc_network.vpc_self_link
}

output "subnet_names" {
  description = "Map of subnet names in development environment"
  value       = module.vpc_network.subnet_names
}

output "subnet_self_links" {
  description = "Map of subnet self-links in development environment"
  value       = module.vpc_network.subnet_self_links
}

output "vpc_connector_name" {
  description = "Name of the VPC connector for serverless services"
  value       = module.vpc_network.vpc_connector_name
}

# Cloud Functions Outputs
output "cloud_functions" {
  description = "Map of Cloud Function names to their details"
  value       = module.cloud_functions.function_details
}

output "function_urls" {
  description = "Map of Cloud Function trigger URLs"
  value       = module.cloud_functions.function_urls
  sensitive   = true
}

output "functions_source_bucket" {
  description = "Cloud Functions source code bucket name"
  value       = module.cloud_functions.source_bucket_name
}

output "functions_service_account" {
  description = "Service account email used by Cloud Functions"
  value       = module.cloud_functions.service_account_email
}

# Cloud Run Outputs
output "cloudrun_services" {
  description = "Map of Cloud Run service details"
  value       = module.cloud_run.service_details
}

output "cloudrun_service_urls" {
  description = "Map of Cloud Run service URLs"
  value       = module.cloud_run.service_urls
}

output "cloudrun_service_account" {
  description = "Service account email used by Cloud Run services"
  value       = module.cloud_run.service_account_email
}

# Vertex AI Outputs
output "vertex_pipeline_sa" {
  description = "Vertex AI pipeline service account email"
  value       = module.vertex_ai.pipeline_sa_email
}

output "vertex_training_sa" {
  description = "Vertex AI training service account email"
  value       = module.vertex_ai.training_sa_email
}

output "vertex_service_agent" {
  description = "Vertex AI service agent email"
  value       = module.vertex_ai.vertex_service_agent
}

output "vertex_workbench_instance" {
  description = "Vertex AI Workbench instance name"
  value       = module.vertex_ai.workbench_instance_name
}

output "vertex_dataset_ids" {
  description = "Map of created Vertex AI dataset IDs"
  value       = module.vertex_ai.dataset_ids
}

output "vertex_model_bucket" {
  description = "Vertex AI model storage bucket name"
  value       = module.vertex_ai.model_bucket_name
}

output "vertex_staging_bucket" {
  description = "Vertex AI staging bucket name"
  value       = module.vertex_ai.staging_bucket_name
}

# Database Outputs
output "database_instance_name" {
  description = "Cloud SQL instance name"
  value       = var.enable_database ? module.database[0].instance_name : null
}

output "database_connection_name" {
  description = "Cloud SQL instance connection name"
  value       = var.enable_database ? module.database[0].connection_name : null
}

output "database_private_ip" {
  description = "Cloud SQL instance private IP address"
  value       = var.enable_database ? module.database[0].private_ip_address : null
  sensitive   = true
}

# Storage Outputs
output "storage_buckets" {
  description = "Map of created storage bucket details"
  value       = module.storage.bucket_details
}

output "storage_bucket_urls" {
  description = "Map of storage bucket URLs"
  value       = module.storage.bucket_urls
}

# Monitoring Outputs
output "monitoring_dashboard_url" {
  description = "URL to the development monitoring dashboard"
  value       = module.monitoring.dashboard_url
}

output "uptime_check_ids" {
  description = "List of uptime check IDs"
  value       = module.monitoring.uptime_check_ids
}

output "notification_channels" {
  description = "List of notification channel IDs"
  value       = module.monitoring.notification_channel_ids
}

# Development Access Outputs
output "dev_access_urls" {
  description = "Map of useful URLs for development access"
  value = {
    cloud_console       = "https://console.cloud.google.com/home/dashboard?project=${var.project_id}"
    cloud_run_services  = "https://console.cloud.google.com/run?project=${var.project_id}"
    cloud_functions     = "https://console.cloud.google.com/functions/list?project=${var.project_id}"
    vertex_ai_workbench = "https://console.cloud.google.com/vertex-ai/workbench?project=${var.project_id}"
    monitoring          = "https://console.cloud.google.com/monitoring?project=${var.project_id}"
    logs                = "https://console.cloud.google.com/logs?project=${var.project_id}"
  }
}

# Cost Information
output "estimated_monthly_cost" {
  description = "Estimated monthly cost for development environment (USD)"
  value = {
    compute_engine    = "5-15"
    cloud_run        = "0-10"
    cloud_functions  = "0-5"
    cloud_sql        = "7-15"
    storage          = "1-5"
    networking       = "2-8"
    vertex_ai        = "10-30"
    total_range      = "25-88"
    note            = "Costs vary based on usage. Preemptible instances and auto-shutdown reduce costs significantly."
  }
}

# Environment Information
output "environment_info" {
  description = "Development environment configuration summary"
  value = {
    project_id          = var.project_id
    environment         = "dev"
    region              = var.region
    vpc_name           = var.vpc_name
    database_enabled   = var.enable_database
    monitoring_enabled = var.enable_monitoring
    preemptible_enabled = var.enable_preemptible_instances
    auto_shutdown_enabled = var.auto_shutdown_enabled
    deployed_timestamp = timestamp()
  }
}

# Quick Start Commands
output "dev_commands" {
  description = "Useful commands for development environment"
  value = {
    cloud_shell = "gcloud cloud-shell ssh --project=${var.project_id}"
    view_logs   = "gcloud logging read 'resource.type=cloud_run_revision OR resource.type=cloud_function' --project=${var.project_id} --limit=50"
    list_services = {
      cloud_run     = "gcloud run services list --project=${var.project_id} --region=${var.region}"
      cloud_functions = "gcloud functions list --project=${var.project_id} --region=${var.region}"
      databases     = "gcloud sql instances list --project=${var.project_id}"
    }
    connect_database = var.enable_database ? "gcloud sql connect ${module.database[0].instance_name} --user=postgres --project=${var.project_id}" : "Database not enabled"
  }
}
