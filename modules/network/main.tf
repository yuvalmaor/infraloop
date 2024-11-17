# modules/network/main.tf
resource "random_id" "suffix" {
  byte_length = 4
  keepers = {
    # Generate a new id each time
    timestamp = timestamp()
  }
}

resource "google_compute_network" "vpc_network" {
  name                    = "${var.network_name}-${random_id.suffix.hex}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.network_name}-subnet-${random_id.suffix.hex}"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "allow_http_ssh" {
  name    = "${var.network_name}-allow-http-ssh-${random_id.suffix.hex}"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

