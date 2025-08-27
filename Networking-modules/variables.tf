# modules/vpc-network/variables.tf

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for regional resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "vpc"
}

variable "mtu" {
  description = "Maximum Transmission Unit in bytes"
  type        = number
  default     = 1460
  
  validation {
    condition     = var.mtu >= 1460 && var.mtu <= 1500
    error_message = "MTU must be between 1460 and 1500."
  }
}

variable "routing_mode" {
  description = "Network routing mode"
  type        = string
  default     = "REGIONAL"
  
  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "Routing mode must be REGIONAL or GLOBAL."
  }
}

variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name          = string
    ip_cidr_range = string
    region        = string
    purpose       = optional(string)
    role          = optional(string)
    stack_type    = optional(string, "IPV4_ONLY")
    ipv6_access_type = optional(string)
    secondary_ranges = list(object({
      range_name    = string
      ip_cidr_range = string
    }))
  }))
  default = []
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

variable "flow_logs_config" {
  description = "Configuration for VPC flow logs"
  type = object({
    aggregation_interval = string
    flow_sampling       = number
    metadata           = string
    metadata_fields    = list(string)
  })
  default = {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling       = 0.5
    metadata           = "INCLUDE_ALL_METADATA"
    metadata_fields    = []
  }
}

variable "firewall_rules" {
  description = "List of firewall rules to create"
  type = list(object({
    name                    = string
    description            = optional(string)
    direction              = string
    priority               = number
    source_ranges          = optional(list(string))
    source_tags            = optional(list(string))
    source_service_accounts = optional(list(string))
    destination_ranges     = optional(list(string))
    target_tags            = optional(list(string))
    target_service_accounts = optional(list(string))
    disabled               = optional(bool, false)
    enable_logging         = optional(bool, false)
    allow = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
    deny = optional(list(object({
      protocol = string
      ports    = optional(list(string))
    })), [])
  }))
  default = []
}

variable "enable_iap_ssh" {
  description = "Enable SSH access from Identity-Aware Proxy"
  type        = bool
  default     = true
}

variable "enable_health_check_firewall" {
  description = "Enable firewall rule for Google Cloud health checks"
  type        = bool
  default     = true
}

# NAT Gateway variables
variable "enable_nat_gateway" {
  description = "Enable Cloud NAT Gateway"
  type        = bool
  default     = true
}

variable "nat_gateway_count" {
  description = "Number of NAT gateways to create"
  type        = number
  default     = 1
}

variable "nat_ip_allocate_option" {
  description = "NAT IP allocation option"
  type        = string
  default     = "AUTO_ONLY"
  
  validation {
    condition     = contains(["AUTO_ONLY", "MANUAL_ONLY"], var.nat_ip_allocate_option)
    error_message = "NAT IP allocation option must be AUTO_ONLY or MANUAL_ONLY."
  }
}

variable "nat_ips_per_gateway" {
  description = "Number of external IPs to allocate per NAT gateway (when using MANUAL_ONLY)"
  type        = number
  default     = 1
}

variable "nat_source_subnetwork_ip_ranges" {
  description = "NAT source subnetwork IP ranges configuration"
  type        = string
  default     = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  
  validation {
    condition = contains([
      "ALL_SUBNETWORKS_ALL_IP_RANGES",
      "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES",
      "LIST_OF_SUBNETWORKS"
    ], var.nat_source_subnetwork_ip_ranges)
    error_message = "Invalid NAT source subnetwork IP ranges option."
  }
}

variable "nat_subnetworks" {
  description = "List of subnetworks for NAT (when using LIST_OF_SUBNETWORKS)"
  type = list(object({
    name                    = string
    source_ip_ranges_to_nat = list(string)
    secondary_ip_range_names = optional(list(string), [])
  }))
  default = []
}

variable "nat_log_config" {
  description = "NAT logging configuration"
  type = object({
    enable = bool
    filter = string
  })
  default = {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

variable "nat_min_ports_per_vm" {
  description = "Minimum number of ports allocated to a VM from this NAT"
  type        = number
  default     = 64
}

variable "nat_max_ports_per_vm" {
  description = "Maximum number of ports allocated to a VM from this NAT"
  type        = number
  default     = 65536
}

variable "nat_enable_eim" {
  description = "Enable endpoint independent mapping for NAT"
  type        = bool
  default     = false
}

variable "nat_udp_idle_timeout_sec" {
  description = "Timeout for UDP connections in seconds"
  type        = number
  default     = 30
}

variable "nat_tcp_established_idle_timeout_sec" {
  description = "Timeout for established TCP connections in seconds"
  type        = number
  default     = 1200
}

variable "nat_tcp_transitory_idle_timeout_sec" {
  description = "Timeout for transitory TCP connections in seconds"
  type        = number
  default     = 30
}

variable "nat_icmp_idle_timeout_sec" {
  description = "Timeout for ICMP connections in seconds"
  type        = number
  default     = 30
}

# Router variables
variable "router_asn" {
  description = "Router ASN"
  type        = number
  default     = 64514
}

variable "router_advertise_mode" {
  description = "Router advertisement mode"
  type        = string
  default     = "DEFAULT"
  
  validation {
    condition     = contains(["DEFAULT", "CUSTOM"], var.router_advertise_mode)
    error_message = "Router advertise mode must be DEFAULT or CUSTOM."
  }
}

variable "router_advertised_groups" {
  description = "List of advertised groups for the router"
  type        = list(string)
  default     = ["ALL_SUBNETS"]
}

variable "router_advertised_ip_ranges" {
  description = "List of advertised IP ranges for the router"
  type = list(object({
    range       = string
    description = string
  }))
  default = []
}

# Private services variables
variable "enable_private_services" {
  description = "Enable private services access (for Cloud SQL, etc.)"
  type        = bool
  default     = true
}

variable "private_services_cidr_prefix" {
  description = "CIDR prefix length for private services"
  type        = number
  default     = 16
}

# VPC Connector variables
variable "create_vpc_connector" {
  description = "Create VPC Access Connector for serverless services"
  type        = bool
  default     = true
}

variable "vpc_connector_cidr" {
  description = "CIDR range for VPC Access Connector"
  type        = string
  default     = "10.8.0.0/28"
}

variable "vpc_connector_machine_type" {
  description = "Machine type for VPC Access Connector"
  type        = string
  default     = "e2-micro"
}

variable "vpc_connector_min_instances" {
  description = "Minimum number of instances for VPC Access Connector"
  type        = number
  default     = 2
}

variable "vpc_connector_max_instances" {
  description = "Maximum number of instances for VPC Access Connector"
  type        = number
  default     = 3
}

variable "vpc_connector_min_throughput" {
  description = "Minimum throughput for VPC Access Connector in Mbps"
  type        = number
  default     = 200
}

variable "vpc_connector_max_throughput" {
  description = "Maximum throughput for VPC Access Connector in Mbps"
  type        = number
  default     = 300
}

# DNS variables
variable "create_private_dns_zone" {
  description = "Create private DNS zone"
  type        = bool
  default     = false
}

variable "private_dns_zone_name" {
  description = "Name of the private DNS zone"
  type        = string
  default     = "internal.local."
}

# Shared VPC variables
variable "enable_shared_vpc_host" {
  description = "Enable this project as a Shared VPC host"
  type        = bool
  default     = false
}

variable "shared_vpc_service_projects" {
  description = "List of service project IDs to attach to this host project"
  type        = list(string)
  default     = []
}

# Security policies
variable "security_policies" {
  description = "Map of security policies to create"
  type = map(object({
    description = string
    rules = list(object({
      action      = string
      priority    = number
      description = optional(string)
      match = object({
        versioned_expr = optional(string)
        config = optional(object({
          src_ip_ranges = list(string)
        }))
      })
    }))
  }))
  default = {}
}

# Labels
variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
