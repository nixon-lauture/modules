# modules/vertex-ai/variables.tf

variable "project_id" {
  type        = string
  description = "GCP project ID."
}

variable "region" {
  type        = string
  description = "Default region for Vertex AI (e.g., us-central1)."
  default     = "us-central1"
}

variable "model_bucket_name" {
  type        = string
  description = "Optional GCS bucket that stores models/artifacts."
  default     = null
}

variable "staging_bucket_name" {
  type        = string
  description = "Optional GCS bucket for Vertex staging/temp."
  default     = null
}

variable "developer_principals" {
  type        = list(string)
  description = "Users/groups/service accounts to grant roles/aiplatform.user (e.g., user:you@example.com)."
  default     = []
}
