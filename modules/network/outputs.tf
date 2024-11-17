output "network_name" {
  value = google_compute_network.vpc_network.name
}

output "subnet_name" {
  value = google_compute_subnetwork.subnet.name
}

#output "static_ip" {
#  value = google_compute_address.static_ip.address
#}


