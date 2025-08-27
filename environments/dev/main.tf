# Root main.tf - GCP Infrastructure
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

# Configure providers
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Local values for common configurations
locals {
  environment = var.environment
  project_name = var.project_name
  
  common_labels = merge(var.common_labels, {
    environment = local.environment
    project     = local.project_name
    managed_by  = "terraform"
  })
}

# Networking Module
module "networking" {
  source = "./Networking-modules"
  
  project_id    = var.project_id
  environment   = local.environment
  project_name  = local.project_name
  region        = var.region
  common_labels = local.common_labels
  
  # Network configuration
  vpc_name           = var.vpc_name
  subnet_configs     = var.subnet_configs
  firewall_rules     = var.firewall_rules
  enable_nat_gateway = var.enable_nat_gateway
}

# Cloud Functions Module
module "cloud_functions" {
  source = "./Cloud-Functions"
  
  project_id    = var.project_id
  environment   = local.environment
  project_name  = local.project_name
  region        = var.region
  common_labels = local.common_labels
  
  # Pass networking info
  vpc_connector_name = module.networking.vpc_connector_name
  
  # Function configurations
  functions_config = var.functions_config
}

# CloudRun Module
module "cloudrun" {
  source = "./cloudrun-modules"
  
  project_id    = var.project_id
  environment   = local.environment
  project_name  = local.project_name
  region        = var.region
  common_labels = local.common_labels
  
  # CloudRun specific variables
  services_config = var.cloudrun_services_config
}

# Development Environment
module "dev_environment" {
  source = "./env/dev"
  count  = var.environment == "dev" ? 1 : 0
  
  project_id    = var.project_id
  environment   = "dev"
  project_name  = local.project_name
  region        = var.region
  zone          = var.zone
  common_labels = local.common_labels
  
  # Development specific overrides
  machine_type = "e2-micro"
  min_replicas = 1
  max_replicas = 2
}

# VertexAI Module
module "vertex_ai" {
  source = "./vertexAI-modules"
  
  project_id    = var.project_id
  environment   = local.environment
  project_name  = local.project_name
  region        = var.region
  zone          = var.zone
  common_labels = local.common_labels
  
  # Vertex AI configurations
  vertex_ai_config = var.vertex_ai_config
}

# Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "vpc_self_link" {
  description = "VPC self link"
  value       = module.networking.vpc_self_link
}

output "subnet_self_links" {
  description = "Subnet self links"
  value       = module.networking.subnet_self_links
}

output "cloud_function_urls" {
  description = "Cloud Function URLs"
  value       = module.cloud_functions.function_urls
  sensitive   = true
}

output "cloudrun_urls" {
  description = "CloudRun service URLs"
  value       = module.cloudrun.service_urls
}

output "vertex_ai_endpoints" {
  description = "Vertex AI endpoint URLs"
  value       = module.vertex_ai.endpoint_urls
}
