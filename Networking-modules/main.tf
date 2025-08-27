
/******************************************
	VPC configuration
 *****************************************/
# modules/vpc-network/main.tf

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "vpcaccess.googleapis.com",
    "dns.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ])
  
  service            = each.value
  disable_on_destroy = false
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-${var.environment}-${var.vpc_name}"
  auto_create_subnetworks = false
  mtu                     = var.mtu
  routing_mode           = var.routing_mode
  description            = "VPC network for ${var.project_id} ${var.environment} environment"
  
  depends_on = [google_project_service.required_apis]
}

# Subnets
resource "google_compute_subnetwork" "subnets" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }
  
  name          = "${var.project_id}-${var.environment}-${each.value.name}"
  ip_cidr_range = each.value.ip_cidr_range
  region        = each.value.region
  network       = google_compute_network.vpc.id
  description   = "Subnet ${each.value.name} in ${var.environment} environment"
  
  # Enable Private Google Access
  private_ip_google_access = var.enable_private_google_access
  
  # Enable flow logs if specified
  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = var.flow_logs_config.aggregation_interval
      flow_sampling       = var.flow_logs_config.flow_sampling
      metadata           = var.flow_logs_config.metadata
      metadata_fields    = var.flow_logs_config.metadata_fields
    }
  }
  
  # Secondary IP ranges for GKE or other services
  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
  
  purpose          = lookup(each.value, "purpose", null)
  role            = lookup(each.value, "role", null)
  stack_type      = lookup(each.value, "stack_type", "IPV4_ONLY")
  ipv6_access_type = lookup(each.value, "ipv6_access_type", null)
}

# Cloud Router for NAT Gateway
resource "google_compute_router" "router" {
  count = var.enable_nat_gateway ? var.nat_gateway_count : 0
  
  name    = "${var.project_id}-${var.environment}-router-${count.index + 1}"
  region  = var.region
  network = google_compute_network.vpc.id
  
  bgp {
    asn               = var.router_asn
    advertise_mode    = var.router_advertise_mode
    advertised_groups = var.router_advertised_groups
    
    dynamic "advertised_ip_ranges" {
      for_each = var.router_advertised_ip_ranges
      content {
        range       = advertised_ip_ranges.value.range
        description = advertised_ip_ranges.value.description
      }
    }
  }
}

# External IP addresses for NAT
resource "google_compute_address" "nat_external_ips" {
  count = var.enable_nat_gateway ? var.nat_gateway_count * var.nat_ips_per_gateway : 0
  
  name   = "${var.project_id}-${var.environment}-nat-ip-${count.index + 1}"
  region = var.region
  
  depends_on = [google_project_service.required_apis]
}

# Cloud NAT
resource "google_compute_router_nat" "nat" {
  count = var.enable_nat_gateway ? var.nat_gateway_count : 0
  
  name   = "${var.project_id}-${var.environment}-nat-${count.index + 1}"
  router = google_compute_router.router[count.index].name
  region = var.region
  
  nat_ip_allocate_option = var.nat_ip_allocate_option
  
  # Use specific external IPs if configured
  nat_ips = var.nat_ip_allocate_option == "MANUAL_ONLY" ? [
    for i in range(var.nat_ips_per_gateway) : 
    google_compute_address.nat_external_ips[count.index * var.nat_ips_per_gateway + i].self_link
  ] : null
  
  source_subnetwork_ip_ranges_to_nat = var.nat_source_subnetwork_ip_ranges
  
  # Subnet configuration
  dynamic "subnetwork" {
    for_each = var.nat_source_subnetwork_ip_ranges == "LIST_OF_SUBNETWORKS" ? var.nat_subnetworks : []
    content {
      name                    = google_compute_subnetwork.subnets[subnetwork.value.name].id
      source_ip_ranges_to_nat = subnetwork.value.source_ip_ranges_to_nat
      
      dynamic "secondary_ip_range_names" {
        for_each = lookup(subnetwork.value, "secondary_ip_range_names", [])
        content {
          name = secondary_ip_range_names.value
        }
      }
    }
  }
  
  # Logging configuration
  log_config {
    enable = var.nat_log_config.enable
    filter = var.nat_log_config.filter
  }
  
  # Port allocation
  min_ports_per_vm               = var.nat_min_ports_per_vm
  max_ports_per_vm               = var.nat_max_ports_per_vm
  enable_endpoint_independent_mapping = var.nat_enable_eim
  
  # Timeouts
  udp_idle_timeout_sec             = var.nat_udp_idle_timeout_sec
  tcp_established_idle_timeout_sec = var.nat_tcp_established_idle_timeout_sec
  tcp_transitory_idle_timeout_sec  = var.nat_tcp_transitory_idle_timeout_sec
  icmp_idle_timeout_sec           = var.nat_icmp_idle_timeout_sec
}

# Firewall Rules
resource "google_compute_firewall" "rules" {
  for_each = { for rule in var.firewall_rules : rule.name => rule }
  
  name    = "${var.project_id}-${var.environment}-${each.value.name}"
  network = google_compute_network.vpc.name
  
  description = lookup(each.value, "description", "Firewall rule ${each.value.name}")
  direction   = each.value.direction
  priority    = each.value.priority
  disabled    = lookup(each.value, "disabled", false)
  
  # Source configuration for INGRESS rules
  source_ranges           = each.value.direction == "INGRESS" ? lookup(each.value, "source_ranges", []) : null
  source_tags            = each.value.direction == "INGRESS" ? lookup(each.value, "source_tags", []) : null
  source_service_accounts = each.value.direction == "INGRESS" ? lookup(each.value, "source_service_accounts", []) : null
  
  # Destination configuration for EGRESS rules
  destination_ranges = each.value.direction == "EGRESS" ? lookup(each.value, "destination_ranges", []) : null
  
  # Target configuration
  target_tags            = lookup(each.value, "target_tags", [])
  target_service_accounts = lookup(each.value, "target_service_accounts", [])
  
  # Allow rules
  dynamic "allow" {
    for_each = lookup(each.value, "allow", [])
    content {
      protocol = allow.value.protocol
      ports    = lookup(allow.value, "ports", [])
    }
  }
  
  # Deny rules
  dynamic "deny" {
    for_each = lookup(each.value, "deny", [])
    content {
      protocol = deny.value.protocol
      ports    = lookup(deny.value, "ports", [])
    }
  }
  
  # Logging
  dynamic "log_config" {
    for_each = lookup(each.value, "enable_logging", false) ? [1] : []
    content {
      metadata = "INCLUDE_ALL_METADATA"
    }
  }
}

# Default firewall rules
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_id}-${var.environment}-allow-internal"
  network = google_compute_network.vpc.name
  
  description = "Allow internal communication between subnets"
  direction   = "INGRESS"
  priority    = 1000
  
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
  
  source_ranges = [for subnet in var.subnets : subnet.ip_cidr_range]
}

# SSH access from IAP
resource "google_compute_firewall" "allow_iap_ssh" {
  count = var.enable_iap_ssh ? 1 : 0
  
  name    = "${var.project_id}-${var.environment}-allow-iap-ssh"
  network = google_compute_network.vpc.name
  
  description = "Allow SSH from Identity-Aware Proxy"
  direction   = "INGRESS"
  priority    = 1000
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  
  # IAP IP range
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["iap-ssh"]
}

# Health check firewall rules for load balancers
resource "google_compute_firewall" "allow_health_check" {
  count = var.enable_health_check_firewall ? 1 : 0
  
  name    = "${var.project_id}-${var.environment}-allow-health-check"
  network = google_compute_network.vpc.name
  
  description = "Allow health checks from Google load balancers"
  direction   = "INGRESS"
  priority    = 1000
  
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
}

# VPC Peering for private services (Cloud SQL, etc.)
resource "google_compute_global_address" "private_ip_address" {
  count = var.enable_private_services ? 1 : 0
  
  name          = "${var.project_id}-${var.environment}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_services_cidr_prefix
  network       = google_compute_network.vpc.id
  
  depends_on = [google_project_service.required_apis]
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.enable_private_services ? 1 : 0
  
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
  
  depends_on = [google_project_service.required_apis]
}

# VPC Access Connector for serverless services
resource "google_vpc_access_connector" "connector" {
  count = var.create_vpc_connector ? 1 : 0
  
  name          = "${var.project_id}-${var.environment}-vpc-connector"
  ip_cidr_range = var.vpc_connector_cidr
  network       = google_compute_network.vpc.name
  region        = var.region
  
  machine_type  = var.vpc_connector_machine_type
  min_instances = var.vpc_connector_min_instances
  max_instances = var.vpc_connector_max_instances
  
  min_throughput = var.vpc_connector_min_throughput
  max_throughput = var.vpc_connector_max_throughput
  
  depends_on = [google_project_service.required_apis]
}

# DNS Zone
resource "google_dns_managed_zone" "private_zone" {
  count = var.create_private_dns_zone ? 1 : 0
  
  name        = "${var.project_id}-${var.environment}-private-zone"
  dns_name    = var.private_dns_zone_name
  description = "Private DNS zone for ${var.project_id} ${var.environment}"
  
  visibility = "private"
  
  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc.id
    }
  }
  
  dnssec_config {
    state = "off"  # DNSSEC not supported for private zones
  }
}

# Shared VPC configuration (if enabled)
resource "google_compute_shared_vpc_host_project" "host" {
  count = var.enable_shared_vpc_host ? 1 : 0
  
  project = var.project_id
  
  depends_on = [google_compute_network.vpc]
}

resource "google_compute_shared_vpc_service_project" "service_projects" {
  for_each = var.enable_shared_vpc_host ? toset(var.shared_vpc_service_projects) : []
  
  host_project    = var.project_id
  service_project = each.value
  
  depends_on = [google_compute_shared_vpc_host_project.host]
}

# Network Security Policies (Cloud Armor)
resource "google_compute_security_policy" "policy" {
  for_each = var.security_policies
  
  name        = "${var.project_id}-${var.environment}-${each.key}"
  description = each.value.description
  
  dynamic "rule" {
    for_each = each.value.rules
    content {
      action   = rule.value.action
      priority = rule.value.priority
      
      match {
        versioned_expr = lookup(rule.value.match, "versioned_expr", null)
        
        dynamic "config" {
          for_each = lookup(rule.value.match, "config", null) != null ? [rule.value.match.config] : []
          content {
            src_ip_ranges = lookup(config.value, "src_ip_ranges", [])
          }
        }
      }
      
      description = lookup(rule.value, "description", "Security policy rule")
    }
  }
  
  # Default rule
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default allow rule"
  }
}
