# modules/cloud-functions/variables.tf

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Functions"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "functions" {
  description = "Configuration for Cloud Functions"
  type = map(object({
    name                  = string
    description          = string
    runtime              = string
    entry_point          = string
    memory_mb            = number
    timeout_seconds      = number
    max_instances        = number
    min_instances        = number
    environment_variables = map(string)
    trigger_type         = string  # "http", "pubsub", "storage", "scheduler"
    trigger_config       = map(any)
  }))
  default = {}
}

variable "vpc_connector_name" {
  description = "Name of the VPC connector for private networking"
  type        = string
  default     = ""
}

variable "allow_unauthenticated" {
  description = "Allow unauthenticated access to HTTP-triggered functions"
  type        = bool
  default     = false
}

variable "create_data_bucket" {
  description = "Create a data processing bucket for functions"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable monitoring and alerting for functions"
  type        = bool
  default     = true
}

variable "notification_channels" {
  description = "List of notification channel IDs for alerts"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "source_bucket_name" {
  description = "Name of the bucket for function source code (optional)"
  type        = string
  default     = ""
}

variable "data_bucket_name" {
  description = "Name of the bucket for function data processing (optional)"
  type        = string
  default     = ""
}

variable "enable_vpc_connector" {
  description = "Enable VPC connector for functions"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Number of days to retain function logs"
  type        = number
  default     = 30
}

variable "dead_letter_topic" {
  description = "Pub/Sub topic for dead letter queue"
  type        = string
  default     = ""
}

variable "max_retry_attempts" {
  description = "Maximum retry attempts for failed function executions"
  type        = number
  default     = 3
}
