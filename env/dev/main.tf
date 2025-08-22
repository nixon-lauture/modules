# Example: pull bucket names from your storage module (if you have one)
# module "storage" {
#   source = "../../modules/storage"
#   project_id = var.project_id
#   region     = var.region
# }

module "vertex_ai" {
  source = "../../modules/vertex-ai"

  project_id          = var.project_id
  region              = var.region
  model_bucket_name   = var.vertex_model_bucket_name    # or module.storage.model_bucket_name
  staging_bucket_name = var.vertex_staging_bucket_name  # or module.storage.staging_bucket_name

  # Grant devs (or a group) the ability to use Vertex AI
  developer_principals = [
    # "user:nixon@example.com",
    # "group:ml-team@example.com",
  ]
}

output "vertex_pipeline_sa" {
  value = module.vertex_ai.pipeline_sa_email
}

output "vertex_training_sa" {
  value = module.vertex_ai.training_sa_email
}

output "vertex_service_agent" {
  value = module.vertex_ai.vertex_service_agent
}
