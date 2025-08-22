# Enable required services (Vertex AI service agent is created when this API is enabled)
locals {
  required_services = [
    "aiplatform.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "compute.googleapis.com",
    "storage.googleapis.com",
    "serviceusage.googleapis.com",
    "artifactregistry.googleapis.com"
  ]
}

resource "google_project_service" "services" {
  for_each           = toset(local.required_services)
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

# Wait for APIs to be enabled before proceeding
resource "time_sleep" "wait_for_apis" {
  depends_on      = [google_project_service.services]
  create_duration = "60s"
}

# Fix Vertex AI service agent provisioning issue
# This solves the "service agent does not exist" error by forcing Google to provision them
resource "null_resource" "provision_vertex_service_agents" {
  depends_on = [time_sleep.wait_for_apis]

  provisioner "local-exec" {
    command = <<-EOT
      # Trigger service agent provisioning for Vertex AI
      TOKEN=$(gcloud auth print-access-token --project=${var.project_id})
      curl -X POST \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        https://${var.region}-aiplatform.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/endpoints \
        -d '{}' || true
      
      # Wait for service agents to be provisioned
      sleep 120
    EOT
  }

  triggers = {
    project_id = var.project_id
    region     = var.region
  }
}

# Additional wait to ensure service agents are fully ready
resource "time_sleep" "wait_for_agents" {
  depends_on      = [null_resource.provision_vertex_service_agents]
  create_duration = "60s"
}

# Compute the Vertex AI service agent email
# Format: service-${PROJECT_NUMBER}@gcp-sa-aiplatform.iam.gserviceaccount.com
locals {
  vertex_service_agent = "service-${data.google_project.this.number}@gcp-sa-aiplatform.iam.gserviceaccount.com"
}

# Optional: grant the Vertex AI service agent access to your model/staging buckets
resource "google_storage_bucket_iam_member" "agent_model_bucket" {
  count  = var.model_bucket_name == null ? 0 : 1
  bucket = var.model_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${local.vertex_service_agent}"

  depends_on = [time_sleep.wait_for_agents]
}

resource "google_storage_bucket_iam_member" "agent_staging_bucket" {
  count  = var.staging_bucket_name == null ? 0 : 1
  bucket = var.staging_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${local.vertex_service_agent}"

  depends_on = [time_sleep.wait_for_agents]
}

# Service accounts you'll use from CI/CD, Cloud Functions/Run, or notebooks
resource "google_service_account" "pipeline" {
  account_id   = "vertex-pipeline"
  display_name = "Vertex Pipelines SA"
  project      = var.project_id
  depends_on   = [google_project_service.services]
}

resource "google_service_account" "training" {
  account_id   = "vertex-training"
  display_name = "Vertex Training/Batch Jobs SA"
  project      = var.project_id
  depends_on   = [google_project_service.services]
}

# Project-level roles for those SAs (least-privilege starter set)
resource "google_project_iam_member" "pipeline_vertex_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.pipeline.email}"
}

resource "google_project_iam_member" "training_vertex_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.training.email}"
}

# Allow these SAs to read/write model artifacts if buckets provided
resource "google_storage_bucket_iam_member" "pipeline_model_bucket" {
  count  = var.model_bucket_name == null ? 0 : 1
  bucket = var.model_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.pipeline.email}"
}

resource "google_storage_bucket_iam_member" "training_model_bucket" {
  count  = var.model_bucket_name == null ? 0 : 1
  bucket = var.model_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.training.email}"
}

resource "google_storage_bucket_iam_member" "pipeline_staging_bucket" {
  count  = var.staging_bucket_name == null ? 0 : 1
  bucket = var.staging_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.pipeline.email}"
}

resource "google_storage_bucket_iam_member" "training_staging_bucket" {
  count  = var.staging_bucket_name == null ? 0 : 1
  bucket = var.staging_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.training.email}"
}

# (Optional) grant your human/dev principals access to use Vertex AI
resource "google_project_iam_member" "dev_vertex_user" {
  for_each = toset(var.developer_principals)
  project  = var.project_id
  role     = "roles/aiplatform.user"
  member   = each.value
}
