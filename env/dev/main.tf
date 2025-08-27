# env/dev/main.tf - Development Environment

# VPC Network Module
module "vpc_network" {
  source = "../../modules/vpc-network"
  
  project_id   = var.project_id
  region       = var.region
  environment  = "dev"
  
  # Development-specific network configuration
  vpc_name = var.vpc_name
  subnets = var.dev_subnets
  
  # Cost optimization - single NAT gateway for dev
  enable_nat_gateway = true
  nat_gateway_count  = 1
  
  # Development firewall rules
  firewall_rules = var.dev_firewall_rules
  
  # Enable flow logs for debugging
  enable_flow_logs = true
}

# Cloud Functions Module
module "cloud_functions" {
  source = "../../modules/cloud-functions"
  
  project_id  = var.project_id
  region      = var.region
  environment = "dev"
  
  # Use VPC connector from networking module
  vpc_connector_name = module.vpc_network.vpc_connector_name
  
  # Development functions configuration
  functions = var.dev_functions_config
  
  # Storage buckets for function sources and data
  source_bucket_name = var.functions_source_bucket_name
  data_bucket_name   = var.functions_data_bucket_name
  
  depends_on = [module.vpc_network]
}

# Cloud Run Module
module "cloud_run" {
  source = "../../modules/cloud-run"
  
  project_id  = var.project_id
  region      = var.region
  environment = "dev"
  
  # Development services configuration
  services = var.dev_cloudrun_services
  
  # Use VPC connector for private networking
  vpc_connector_name = module.vpc_network.vpc_connector_name
  
  # Development-specific settings
  allow_unauthenticated = var.allow_unauthenticated_access
  
  depends_on = [module.vpc_network]
}

# Vertex AI Module
module "vertex_ai" {
  source = "../../modules/vertex-ai"
  
  project_id          = var.project_id
  region              = var.region
  environment         = "dev"
  
  model_bucket_name   = var.vertex_model_bucket_name    # or module.storage.model_bucket_name
  staging_bucket_name = var.vertex_staging_bucket_name  # or module.storage.staging_bucket_name
  
  # Grant devs (or a group) the ability to use Vertex AI
  developer_principals = var.vertex_developer_principals
  
  # Development-specific AI configuration
  enable_training_pipeline = var.enable_vertex_training
  enable_endpoints        = var.enable_vertex_endpoints
  enable_workbench        = true  # Always enable workbench in dev
  
  # Workbench configuration for development
  workbench_config = {
    machine_type     = "n1-standard-2"
    disk_size_gb     = 100
    enable_gpu       = false
    image_family     = "tf-2-11-cu113-notebooks"
    idle_shutdown    = true  # Auto-shutdown for cost savings
  }
  
  depends_on = [module.vpc_network]
}

# Development Database (Cloud SQL)
module "database" {
  source = "../../modules/database"
  count  = var.enable_database ? 1 : 0
  
  project_id  = var.project_id
  region      = var.region
  environment = "dev"
  
  # Development database configuration
  database_config = {
    instance_name    = "${var.project_name}-dev-db"
    database_version = "POSTGRES_14"
    tier            = "db-f1-micro"  # Smallest instance for dev
    disk_size       = 20
    backup_enabled  = false  # Disable backups in dev for cost
    ha_enabled      = false  # No HA in dev
  }
  
  # Use private IP from VPC
  private_network = module.vpc_network.vpc_self_link
  
  depends_on = [module.vpc_network]
}

# Development Storage
module "storage" {
  source = "../../modules/storage"
  
  project_id  = var.project_id
  region      = var.region
  environment = "dev"
  
  # Development storage buckets
  buckets = var.dev_storage_buckets
  
  # Lifecycle policies for cost optimization
  enable_lifecycle_policies = true
  lifecycle_config = {
    delete_after_days = 30  # Auto-delete old dev data
    archive_after_days = 7   # Archive after a week
  }
}

# Development Monitoring
module "monitoring" {
  source = "../../modules/monitoring"
  
  project_id  = var.project_id
  region      = var.region
  environment = "dev"
  
  # Development monitoring configuration
  enable_uptime_checks = var.enable_monitoring
  enable_alerting     = var.enable_alerting
  
  # Alert contacts
  notification_channels = var.dev_notification_channels
  
  # Monitor all deployed services
  monitored_services = {
    cloud_run_services = module.cloud_run.service_urls
    cloud_functions   = module.cloud_functions.function_urls
    database_instance = var.enable_database ? [module.database[0].instance_name] : []
  }
  
  depends_on = [
    module.cloud_run,
    module.cloud_functions,
    module.database
  ]
}
