# env/dev/variables.tf - Development Environment Variables

variable "project_id" {
  type        = string
  description = "Project ID for dev environment"
}

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
  default     = "my-project"
}

variable "region" {
  type        = string
  description = "GCP region for dev resources"
  default     = "us-central1"
}

# Networking Variables
variable "vpc_name" {
  type        = string
  description = "VPC network name for dev environment"
  default     = "dev-vpc"
}

variable "dev_subnets" {
  type = list(object({
    name               = string
    ip_cidr_range     = string
    region            = string
    secondary_ranges  = list(object({
      range_name     = string
      ip_cidr_range  = string
    }))
  }))
  description = "Subnet configuration for dev environment"
  default = [
    {
      name          = "dev-subnet-main"
      ip_cidr_range = "10.1.0.0/24"
      region        = "us-central1"
      secondary_ranges = [
        {
          range_name    = "dev-pods"
          ip_cidr_range = "10.2.0.0/16"
        },
        {
          range_name    = "dev-services"
          ip_cidr_range = "10.3.0.0/16"
        }
      ]
    }
  ]
}

variable "dev_firewall_rules" {
  type = list(object({
    name        = string
    direction   = string
    priority    = number
    ranges      = list(string)
    ports       = list(string)
    protocols   = list(string)
    target_tags = list(string)
  }))
  description = "Firewall rules for dev environment"
  default = [
    {
      name        = "dev-allow-http"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["0.0.0.0/0"]
      ports       = ["80", "8080"]
      protocols   = ["tcp"]
      target_tags = ["dev-http"]
    },
    {
      name        = "dev-allow-https"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["0.0.0.0/0"]
      ports       = ["443", "8443"]
      protocols   = ["tcp"]
      target_tags = ["dev-https"]
    },
    {
      name        = "dev-allow-ssh"
      direction   = "INGRESS"
      priority    = 1000
      ranges      = ["35.235.240.0/20"]  # Cloud Shell IP range
      ports       = ["22"]
      protocols   = ["tcp"]
      target_tags = ["dev-ssh"]
    }
  ]
}

# Cloud Functions Variables
variable "functions_source_bucket_name" {
  type        = string
  description = "Bucket name for Cloud Functions source code"
  default     = null
}

variable "functions_data_bucket_name" {
  type        = string
  description = "Bucket name for Cloud Functions data processing"
  default     = null
}

variable "dev_functions_config" {
  type = map(object({
    name                = string
    description         = string
    runtime            = string
    entry_point        = string
    memory_mb          = number
    timeout_seconds    = number
    environment_variables = map(string)
    trigger_type       = string
    trigger_config     = map(any)
  }))
  description = "Cloud Functions configuration for dev environment"
  default = {
    api_processor = {
      name                = "dev-api-processor"
      description         = "Development API processor function"
      runtime            = "python39"
      entry_point        = "main"
      memory_mb          = 256
      timeout_seconds    = 60
      environment_variables = {
        ENVIRONMENT = "dev"
        LOG_LEVEL   = "DEBUG"
      }
      trigger_type   = "http"
      trigger_config = {}
    }
  }
}

# Cloud Run Variables
variable "dev_cloudrun_services" {
  type = map(object({
    name              = string
    image             = string
    port              = number
    cpu               = string
    memory            = string
    min_instances     = number
    max_instances     = number
    environment_variables = map(string)
    secrets           = map(string)
  }))
  description = "Cloud Run services configuration for dev environment"
  default = {
    web_app = {
      name              = "dev-web-app"
      image             = "gcr.io/cloudrun/hello"
      port              = 8080
      cpu               = "1"
      memory            = "512Mi"
      min_instances     = 0
      max_instances     = 3
      environment_variables = {
        NODE_ENV    = "development"
        LOG_LEVEL   = "debug"
      }
      secrets = {}
    }
  }
}

variable "allow_unauthenticated_access" {
  type        = bool
  description = "Allow unauthenticated access to Cloud Run services in dev"
  default     = true
}

# Vertex AI Variables
variable "vertex_model_bucket_name" {
  type        = string
  description = "Bucket name for Vertex AI models"
  default     = null
}

variable "vertex_staging_bucket_name" {
  type        = string
  description = "Bucket name for Vertex AI staging"
  default     = null
}

variable "vertex_developer_principals" {
  type        = list(string)
  description = "List of principals who can access Vertex AI in dev"
  default = [
    # "user:developer@example.com",
    # "group:ml-team@example.com",
  ]
}

variable "enable_vertex_training" {
  type        = bool
  description = "Enable Vertex AI training pipelines in dev"
  default     = false
}

variable "enable_vertex_endpoints" {
  type        = bool
  description = "Enable Vertex AI endpoints in dev"
  default     = true
}

# Database Variables
variable "enable_database" {
  type        = bool
  description = "Enable Cloud SQL database in dev environment"
  default     = true
}

# Storage Variables
variable "dev_storage_buckets" {
  type = map(object({
    name                     = string
    location                = string
    storage_class           = string
    uniform_bucket_access   = bool
    versioning_enabled      = bool
    lifecycle_rules         = list(object({
      age_days = number
      action   = string
    }))
  }))
  description = "Storage buckets for dev environment"
  default = {
    dev_data = {
      name                   = "dev-data-bucket"
      location              = "US"
      storage_class         = "STANDARD"
      uniform_bucket_access = true
      versioning_enabled    = false
      lifecycle_rules = [
        {
          age_days = 30
          action   = "Delete"
        }
      ]
    }
  }
}

# Monitoring Variables
variable "enable_monitoring" {
  type        = bool
  description = "Enable monitoring and uptime checks"
  default     = true
}

variable "enable_alerting" {
  type        = bool
  description = "Enable alerting for dev environment"
  default     = false  # Usually disabled in dev to avoid noise
}

variable "dev_notification_channels" {
  type        = list(string)
  description = "Notification channels for dev alerts"
  default     = []
}

# Cost Optimization Variables
variable "enable_preemptible_instances" {
  type        = bool
  description = "Use preemptible instances where possible for cost savings"
  default     = true
}

variable "auto_shutdown_enabled" {
  type        = bool
  description = "Enable automatic shutdown of resources outside business hours"
  default     = true
}

variable "auto_shutdown_schedule" {
  type        = string
  description = "Cron schedule for auto-shutdown (UTC)"
  default     = "0 22 * * 1-5"  # 10 PM weekdays
}

variable "auto_startup_schedule" {
  type        = string
  description = "Cron schedule for auto-startup (UTC)"
  default     = "0 8 * * 1-5"   # 8 AM weekdays
}

# Developer Access Variables
variable "developer_emails" {
  type        = list(string)
  description = "List of developer email addresses for access grants"
  default     = []
}

variable "dev_team_group" {
  type        = string
  description = "Google Group for development team access"
  default     = ""
}

# Environment Labels
variable "environment_labels" {
  type        = map(string)
  description = "Labels to apply to all dev resources"
  default = {
    environment    = "dev"
    team          = "development"
    cost_center   = "engineering"
    auto_shutdown = "true"
  }
}
