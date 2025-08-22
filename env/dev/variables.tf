# env/dev/variables.tf (root)

variable "project_id" {
  type        = string
  description = "Project ID for dev."
}

variable "region" {
  type        = string
  default     = "us-central1"
}

variable "vertex_model_bucket_name" {
  type        = string
  default     = null
}

variable "vertex_staging_bucket_name" {
  type        = string
  default     = null
}
