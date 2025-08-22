
/******************************************
	VPC configuration
 *****************************************/
resource "google_compute_network" "network" {
  provider                                  = google-beta
  name                                      = var.network_name
  auto_create_subnetworks                   = var.auto_create_subnetworks
  routing_mode                              = var.routing_mode
  project                                   = var.project_id
  description                               = var.description
  delete_default_routes_on_create           = var.delete_default_internet_gateway_routes
  mtu                                       = var.mtu
  enable_ula_internal_ipv6                  = var.enable_ipv6_ula
  internal_ipv6_range                       = var.internal_ipv6_range
  network_firewall_policy_enforcement_order = var.network_firewall_policy_enforcement_order
  network_profile                           = var.network_profile
  bgp_always_compare_med                    = var.bgp_always_compare_med
  bgp_best_path_selection_mode              = var.bgp_best_path_selection_mode
  bgp_inter_region_cost                     = var.bgp_inter_region_cost
}

/******************************************
	Shared VPC
 *****************************************/
resource "google_compute_shared_vpc_host_project" "shared_vpc_host" {

  count      = var.shared_vpc_host ? 1 : 0
  project    = var.project_id
  depends_on = [google_compute_network.network]
}
