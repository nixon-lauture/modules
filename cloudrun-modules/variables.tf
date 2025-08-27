# modules/cloud-run/variables.tf

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Run services"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "services" {
  description = "Configuration for Cloud Run services"
  type = map(object({
    name                  = string
    image                 = string
    port                  = number
    cpu                   = string
    memory                = string
    min_instances         = number
    max_instances         = number
    timeout_seconds       = number
    cpu_idle              = bool
    startup_cpu_boost     = bool
    environment_variables = map(string)
    secrets              = map(object({
      secret_name = string
      version     = string
    }))
    allow_unauthenticated = bool
    authorized_members    = list(string)
    custom_domain        = string
    volumes              = list(object({
      name         = string
      mount_path   = string
      secret_name  = string
      default_mode = number
      items = list(object({
        path    = string
        version = string
        mode    = number
      }))
    }))
    startup_probe = object({
      initial_delay_seconds = number
      timeout_seconds      = number
      period_seconds       = number
      failure_threshold    = number
      path                = string
    })
    liveness_probe = object({
      initial_delay_seconds = number
      timeout_seconds      = number
      period_seconds       = number
      failure_threshold    = number
      path                = string
    })
    health_check_path    = string
    execution_environment = string
    session_affinity     = bool
  }))
  default = {}
}

variable "vpc_connector_name" {
  description = "Name of the VPC connector for private networking"
  type        = string
  default     = ""
}

variable "deletion_protection" {
  description = "Enable deletion protection for Cloud Run services"
  type        = bool
  default     = false
}

variable "create_load_balancer" {
  description = "Create a load balancer for Cloud Run services"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable monitoring and uptime checks"
  type        = bool
  default     = true
}

variable "monitoring_regions" {
  description = "List of regions for uptime checks"
  type        = list(string)
  default     = ["us-central1", "us-east1", "europe-west1"]
}

variable "error_threshold" {
  description = "Error rate threshold for alerting (percentage)"
  type        = number
  default     = 0.05
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

variable "default_cpu" {
  description = "Default CPU allocation for services"
  type        = string
  default     = "1"
}

variable "default_memory" {
  description = "Default memory allocation for services"
  type        = string
  default     = "512Mi"
}

variable "default_timeout" {
  description = "Default timeout for services in seconds"
  type        = number
  default     = 300
}

variable "default_min_instances" {
  description = "Default minimum number of instances"
  type        = number
  default     = 0
}

variable "default_max_instances" {
  description = "Default maximum number of instances"
  type        = number
  default     = 10
}

variable "ingress" {
  description = "Ingress settings for all services"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
  
  validation {
    condition = contains([
      "INGRESS_TRAFFIC_ALL",
      "INGRESS_TRAFFIC_INTERNAL_ONLY",
      "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
    ], var.ingress)
    error_message = "Ingress must be one of INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, or INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER."
  }
}
