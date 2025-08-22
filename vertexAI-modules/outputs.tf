# modules/vertex-ai/outputs.tf

output "vertex_service_agent" {
  value       = local.vertex_service_agent
  description = "Auto-managed Vertex AI service agent email."
}

output "pipeline_sa_email" {
  value       = google_service_account.pipeline.email
  description = "Vertex Pipelines SA email."
}

output "training_sa_email" {
  value       = google_service_account.training.email
  description = "Vertex Training SA email."
}
