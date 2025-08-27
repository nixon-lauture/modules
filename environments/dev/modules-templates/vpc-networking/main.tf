# Networking-modules/main.tf - GCP VPC and Networking

# Enable required APIs
resource "google_project_service" "compute_api" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking_api" {
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

# VPC Network
resource "google_compute_network" "main" {
  name                    = "${var.project_name}-${var.environment}-vpc"
  auto_create_subnetworks = false
  mtu                     = 1460
  routing_mode           = "REGIONAL"
  
  depends_on = [google_project_service.compute_api]
}

# Subnets
resource "google_compute_subnetwork" "main" {
  count = length(var.subnet_configs)
  
  name          = "${var.project_name}-${var.environment}-${var.subnet_configs[count.index].name}"
  ip_cidr_range = var.subnet_configs[count.index].cidr_range
  region        = var.subnet_configs[count.index].region
  network       = google_compute_network.main.id
  
  # Enable Private Google Access
  private_ip_google_access = var.enable_private_google_access
  
  # Enable flow logs if specified
  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = "INTERVAL_10_MIN"
      flow_sampling       = 0.5
      metadata           = "INCLUDE_ALL_METADATA"
    }
  }
  
  # Secondary IP ranges for GKE pods and services
  dynamic "secondary_ip_range" {
    for_each = var.subnet_configs[count.index].secondary_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
}

# Cloud Router for NAT Gateway
resource "google_compute_router" "main" {
  count   = var.enable_nat_gateway ? 1 : 0
  name    = "${var.project_name}-${var.environment}-router"
  region  = var.region
  network = google_compute_network.main.id
  
  bgp {
    asn = 64514
  }
}

# Cloud NAT
resource "google_compute_router_nat" "main" {
  count  = var.enable_nat_gateway ? 1 : 0
  name   = "${var.project_name}-${var.environment}-nat"
  router = google_compute_router.main[0].name
  region = var.region
  
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall Rules
resource "google_compute_firewall" "rules" {
  count = length(var.firewall_rules)
  
  name    = "${var.project_name}-${var.environment}-${var.firewall_rules[count.index].name}"
  network = google_compute_network.main.name
  
  direction = var.firewall_rules[count.index].direction
  priority  = var.firewall_rules[count.index].priority
  
  dynamic "allow" {
    for_each = var.firewall_rules[count.index].protocols
    content {
      protocol = allow.value
      ports    = var.firewall_rules[count.index].ports
    }
  }
  
  source_ranges = var.firewall_rules[count.index].ranges
  target_tags   = var.firewall_rules[count.index].tags
}

# Additional security firewall rules
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-${var.environment}-allow-internal"
  network = google_compute_network.main.name
  
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  
  allow {
    protocol = "icmp"
  }
  
  source_ranges = [for subnet in var.subnet_configs : subnet.cidr_range]
  priority      = 1000
}

# SSH access firewall rule
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-${var.environment}-allow-ssh"
  network = google_compute_network.main.name
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  source_ranges = var.ssh_source_ranges
  target_tags   = ["ssh-access"]
  priority      = 1000
}

# Health check firewall rules for load balancers
resource "google_compute_firewall" "allow_health_check" {
  name    = "${var.project_name}-${var.environment}-allow-health-check"
  network = google_compute_network.main.name
  
  allow {
    protocol = "tcp"
  }
  
  # Google Cloud health check IP ranges
  source_ranges = [
    "209.85.152.0/22",
    "209.85.204.0/22",
    "35.191.0.0/16"
  ]
  
  target_tags = ["health-check"]
  priority    = 1000
}

# VPC Peering for private services (Cloud SQL, etc.)
resource "google_compute_global_address" "private_ip_address" {
  count = var.enable_private_services ? 1 : 0
  
  name          = "${var.project_name}-${var.environment}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.enable_private_services ? 1 : 0
  
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
  
  depends_on = [google_project_service.servicenetworking_api]
}

# VPC Connector for serverless services
resource "google_vpc_access_connector" "main" {
  count         = var.create_vpc_connector ? 1 : 0
  name          = "${var.project_name}-${var.environment}-vpc-connector"
  ip_cidr_range = var.vpc_connector_cidr
  network       = google_compute_network.main.name
  region        = var.region
  
  # Machine type for the connector
  machine_type = var.vpc_connector_machine_type
  min_instances = var.vpc_connector_min_instances
  max_instances = var.vpc_connector_max_instances
  
  depends_on = [google_project_service.vpcaccess_api]
}

# Enable VPC Access API
resource "google_project_service" "vpcaccess_api" {
  count              = var.create_vpc_connector ? 1 : 0
  service            = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}

# Load Balancer components (if needed)
resource "google_compute_global_address" "lb_ip" {
  count = var.create_load_balancer ? 1 : 0
  name  = "${var.project_name}-${var.environment}-lb-ip"
}

resource "google_compute_health_check" "http" {
  count = var.create_load_balancer ? 1 : 0
  name  = "${var.project_name}-${var.environment}-health-check"
  
  timeout_sec        = 5
  check_interval_sec = 10
  
  http_health_check {
    port         = 80
    request_path = "/health"
  }
}

# Backend service for load balancer
resource "google_compute_backend_service" "main" {
  count = var.create_load_balancer ? 1 : 0
  name  = "${var.project_name}-${var.environment}-backend-service"
  
  protocol    = "HTTP"
  timeout_sec = 30
  
  health_checks = [google_compute_health_check.http[0].id]
  
  backend {
    group = google_compute_instance_group.main[0].id
  }
}

# URL map for load balancer
resource "google_compute_url_map" "main" {
  count           = var.create_load_balancer ? 1 : 0
  name            = "${var.project_name}-${var.environment}-url-map"
  default_service = google_compute_backend_service.main[0].id
}

# HTTP(S) proxy
resource "google_compute_target_http_proxy" "main" {
  count   = var.create_load_balancer ? 1 : 0
  name    = "${var.project_name}-${var.environment}-http-proxy"
  url_map = google_compute_url_map.main[0].id
}

# Global forwarding rule
resource "google_compute_global_forwarding_rule" "main" {
  count      = var.create_load_balancer ? 1 : 0
  name       = "${var.project_name}-${var.environment}-forwarding-rule"
  target     = google_compute_target_http_proxy.main[0].id
  port_range = "80"
  ip_address = google_compute_global_address.lb_ip[0].address
}

# Instance group for load balancer targets (placeholder)
resource "google_compute_instance_group" "main" {
  count = var.create_load_balancer ? 1 : 0
  name  = "${var.project_name}-${var.environment}-instance-group"
  zone  = var.zone
  
  network = google_compute_network.main.id
}

# DNS Zone (if custom domain is needed)
resource "google_dns_managed_zone" "main" {
  count = var.create_dns_zone ? 1 : 0
  name  = "${var.project_name}-${var.environment}-zone"
  dns_name = var.dns_zone_name
  description = "DNS zone for ${var.project_name} ${var.environment}"
  
  visibility = "public"
  
  dnssec_config {
    state = "on"
  }
}
