# modules/vpc-network/outputs.tf

output "vpc_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "vpc_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "vpc_self_link" {
  description = "Self-link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "vpc_gateway_ipv4" {
  description = "Gateway IPv4 address of the VPC network"
  value       = google_compute_network.vpc.gateway_ipv4
}

output "vpc_description" {
  description = "Description of the VPC network"
  value       = google_compute_network.vpc.description
}

output "vpc_routing_mode"
