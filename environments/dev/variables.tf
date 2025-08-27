# variables.tf - Root level variables for GCP

# Project Configuration
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "my-gcp-infrastructure"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# GCP Configuration
variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

# Networking Variables
variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "main-vpc"
}

variable "subnet_configs" {
  description = "Configuration for subnets"
  type = list(object({
    name          = string
    cidr_range    = string
    region        = string
    secondary_ranges = list(object({
      range_name    = string
      ip_cidr_range = string
    }))
  }))
  default = [
    {
      name       = "main-subnet"
      cidr_range = "10.0.1.0/24"
      region     = "us-central1"
      secondary_ranges = [
        {
          range_name    = "pods"
          ip_cidr_range = "10.1.0.0/16"
        },
        {
          range_name    = "services"
          ip_cidr_range = "10.2.0.0/16"
        }
      ]
    }
  ]
}

variable "firewall_rules" {
  description = "Firewall rules configuration"
  type = list(object({
    name      = string
    direction = string
    priority  = number
    ranges    = list(string)
    ports     = list(string)
    protocols = list(string)
    tags      = list(string)
  }))
  default = [
    {
      name      = "allow-http"
      direction = "INGRESS"
      priority  = 1000
      ranges    = ["0.0.0.0/0"]
      ports     = ["80", "8080"]
      protocols = ["tcp"]
      tags      = ["http-server"]
    },
    {
      name      = "allow-https"
      direction = "INGRESS"
      priority  = 1000
      ranges    = ["0.0.0.0/0"]
      ports     = ["443"]
      protocols = ["tcp"]
      tags      = ["https-server"]
    }
  ]
}

variable "enable_nat_gateway" {
  description = "Enable Cloud NAT for private instances"
  type        = bool
  default     = true
}

# Cloud Functions Configuration
variable "functions_config" {
  description = "Configuration for Cloud Functions"
  type = map(object({
    name                  = string
    description          = string
    runtime              = string
    entry_point          = string
    source_archive_bucket = string
    source_archive_object = string
    timeout              = number
    memory               = number
    environment_variables = map(string)
    trigger_type         = string
    trigger_config       = map(any)
  }))
  default = {}
}

# CloudRun Configuration
variable "cloudrun_services_config" {
  description = "Configuration for CloudRun services"
  type = map(object({
    name     = string
    image    = string
    port     = number
    cpu      = string
    memory   = string
    min_scale = number
    max_scale = number
    environment_variables = map(string)
    allow_unauthenticated = bool
  }))
  default = {}
}

# Vertex AI Configuration
variable "vertex_ai_config" {
  description = "Configuration for Vertex AI services"
  type = object({
    create_dataset       = bool
    create_model         = bool
    create_endpoint      = bool
    create_featurestore  = bool
    create_workbench     = bool
    dataset_type         = string
    model_config         = map(any)
    endpoint_config      = map(any)
    workbench_config     = map(any)
  })
  default = {
    create_dataset      = false
    create_model        = false
    create_endpoint     = false
    create_featurestore = false
    create_workbench    = false
    dataset_type        = "tabular"
    model_config        = {}
    endpoint_config     = {}
    workbench_config    = {}
  }
}

# Common Labels
variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    owner       = "devops-team"
    environment = "dev"
    project     = "infrastructure"
    cost_center = "engineering"
  }
}

# Feature Flags
variable "enable_monitoring" {
  description = "Enable monitoring and logging"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "enable_private_google_access" {
  description = "Enable Private Google Access for subnets"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = false
}
