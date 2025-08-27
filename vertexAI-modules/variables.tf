# modules/vertex-ai/variables.tf

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Vertex AI resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "model_bucket_name" {
  description = "Storage bucket name for ML models"
  type        = string
  default     = null
}

variable "staging_bucket_name" {
  description = "Storage bucket name for ML staging/artifacts"
  type        = string
  default     = null
}

variable "developer_principals" {
  description = "List of principals who can access Vertex AI resources"
  type        = list(string)
  default     = []
}

variable "datasets" {
  description = "Configuration for Vertex AI datasets"
  type = map(object({
    metadata_schema_uri = string
    description         = string
  }))
  default = {}
}

variable "models" {
  description = "Configuration for Vertex AI model registry entries"
  type = map(object({
    description     = string
    version_aliases = list(string)
  }))
  default = {}
}

variable "endpoints" {
  description = "Configuration for Vertex AI endpoints"
  type = map(object({
    description = string
  }))
  default = {}
}

variable "create_featurestore" {
  description = "Whether to create a Vertex AI Featurestore"
  type        = bool
  default     = false
}

variable "featurestore_config" {
  description = "Configuration for Vertex AI Featurestore"
  type = object({
    fixed_node_count = number
  })
  default = {
    fixed_node_count = 1
  }
}

variable "create_workbench" {
  description = "Whether to create a Vertex AI Workbench instance"
  type        = bool
  default     = false
}

variable "workbench_config" {
  description = "Configuration for Vertex AI Workbench"
  type = object({
    zone                 = string
    machine_type         = string
    image_project        = string
    image_family         = string
    install_gpu_driver   = bool
    accelerator_type     = string
    accelerator_count    = number
    boot_disk_type       = string
    boot_disk_size_gb    = number
    data_disk_type       = string
    data_disk_size_gb    = number
    network              = string
    subnet               = string
    no_public_ip         = bool
    no_proxy_access      = bool
    metadata             = map(string)
    post_startup_script  = string
  })
  default = {
    zone                 = "us-central1-a"
    machine_type         = "n1-standard-2"
    image_project        = "deeplearning-platform-release"
    image_family         = "tf-2-11-cu113-notebooks"
    install_gpu_driver   = false
    accelerator_type     = ""
    accelerator_count    = 0
    boot_disk_type       = "PD_SSD"
    boot_disk_size_gb    = 100
    data_disk_type       = "PD_SSD"
    data_disk_size_gb    = 100
    network              = "default"
    subnet               = "default"
    no_public_ip         = false
    no_proxy_access      = false
    metadata             = {}
    post_startup_script  = ""
  }
}

variable "training_pipelines" {
  description = "Configuration for Vertex AI training pipelines"
  type = map(object({
    machine_type           = string
    accelerator_type       = string
    accelerator_count      = number
    replica_count          = number
    container_image_uri    = string
    args                   = list(string)
    environment_variables  = map(string)
  }))
  default = {}
}

variable "batch_prediction_jobs" {
  description = "Configuration for Vertex AI batch prediction jobs"
  type = map(object({
    model_id               = string
    input_format           = string
    input_uris             = list(string)
    output_format          = string
    machine_type           = string
    accelerator_type       = string
    accelerator_count      = number
    starting_replica_count = number
    max_replica_count      = number
  }))
  default = {}
}

variable "kms_key_name" {
  description = "KMS key name for encryption (optional)"
  type        = string
  default     = ""
}

variable "enable_monitoring" {
  description = "Enable monitoring and alerting for Vertex AI"
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

variable "hyperparameter_tuning_jobs" {
  description = "Configuration for hyperparameter tuning jobs"
  type = map(object({
    study_spec = object({
      metrics = list(object({
        metric_id = string
        goal      = string
      }))
      parameters = list(object({
        parameter_id = string
        value_spec   = map(any)
        scale_type   = string
      }))
      algorithm = string
    })
    max_trial_count      = number
    parallel_trial_count = number
    trial_job_spec = object({
      worker_pool_specs = list(object({
        machine_spec = object({
          machine_type      = string
          accelerator_type  = string
          accelerator_count = number
        })
        replica_count = number
        container_spec = object({
          image_uri             = string
          args                  = list(string)
          environment_variables = map(string)
        })
      }))
    })
  }))
  default = {}
}

variable "model_deployment_configs" {
  description = "Configuration for model deployments to endpoints"
  type = map(object({
    endpoint_id           = string
    model_id              = string
    display_name          = string
    traffic_split         = number
    machine_type          = string
    min_replica_count     = number
    max_replica_count     = number
    accelerator_type      = string
    accelerator_count     = number
  }))
  default = {}
}

variable "pipeline_schedules" {
  description = "Configuration for scheduled pipeline runs"
  type = map(object({
    pipeline_id     = string
    cron_expression = string
    timezone        = string
    enabled         = bool
    parameters      = map(string)
  }))
  default = {}
}

variable "experiment_configs" {
  description = "Configuration for Vertex AI experiments"
  type = map(object({
    description = string
    labels      = map(string)
  }))
  default = {}
}
