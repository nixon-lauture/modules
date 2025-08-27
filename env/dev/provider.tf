# env/dev/provider.tf - Development Environment Provider Configuration

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
  
  # Optional: Configure remote state for development
  # backend "gcs" {
  #   bucket = "your-terraform-state-bucket"
  #   prefix = "dev/terraform.tfstate"
  # }
}

# Provider configuration for development environment
provider "google" {
  project = var.project_id
  region  = var.region
  
  # Development-specific provider settings
  user_project_override = true
  billing_project      = var.project_id
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  
  user_project_override = true
  billing_project      = var.project_id
}
