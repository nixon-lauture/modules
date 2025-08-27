# modules/cloud-run/outputs.tf

output "service_details" {
  description = "Details of all created Cloud Run services"
  value = {
    for name, service in google_cloud_run_v2_service.services : name => {
      name         = service.name
      uri          = service.uri
      location     = service.location
      latest_ready_revision = service.latest_ready_revision
      latest_created_revision = service.latest_created_revision
      observed_generation = service.observed_generation
      conditions     = service.conditions
      traffic       = service.traffic
      terminal_condition = service.terminal_condition
    }
  }
}

output "service_urls" {
  description = "Map of service names to their URLs"
  value = {
    for name, service in google_cloud_run_v2_service.services : name => service.uri
  }
}

output "service_names" {
  description = "List of all Cloud Run service names"
  value = [
    for service in google_cloud_run_v2_service.services : service.name
  ]
}

output "service_account_email" {
  description = "Email of the service account used by Cloud Run services"
  value = google_service_account.cloud_run_sa.email
}

output "service_ids" {
  description = "Map of service names to their IDs"
  value = {
    for name, service in google_cloud_run_v2_service.services : name => service.id
  }
}

output "custom_domains" {
  description = "Map of services with custom domain mappings"
  value = {
    for name, domain in google_cloud_run_domain_mapping.custom_domains : name => {
      domain = domain.name
      status = domain.status
    }
  }
}

output "load_balancer_backend" {
  description = "Load balancer backend service details"
  value = var.create_load_balancer ? {
    name              = google_compute_region_backend_service.cloud_run_backend[0].name
    id                = google_compute_region_backend_service.cloud_run_backend[0].id
    self_link         = google_compute_region_backend_service.cloud_run_backend[0].self_link
    creation_timestamp = google_compute_region_backend_service.cloud_run_backend[0].creation_timestamp
  } : null
}

output "network_endpoint_groups" {
  description = "Map of network endpoint groups for each service"
  value = var.create_load_balancer ? {
    for name, neg in google_compute_region_network_endpoint_group.cloud_run_neg : name => {
      name      = neg.name
      id        = neg.id
      self_link = neg.self_link
    }
  } : {}
}

output "uptime_check_ids" {
  description = "Map of uptime check IDs for each service"
  value = var.enable_monitoring ? {
    for name, check in google_monitoring_uptime_check_config.service_uptime : name => check.uptime_check_id
  } : {}
}

output "monitoring_alert_policy_id" {
  description = "ID of the monitoring alert policy for service errors"
  value = var.enable_monitoring ? google_monitoring_alert_policy.service_errors[0].name : null
}

output "latest_revisions" {
  description = "Map of service names to their latest ready revisions"
  value = {
    for name, service in google_cloud_run_v2_service.services : name => service.latest_ready_revision
  }
}

output "traffic_allocations" {
  description = "Current traffic allocations for all services"
  value = {
    for name, service in google_cloud_run_v2_service.services : name => service.traffic
  }
}
