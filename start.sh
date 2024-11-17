#!/bin/bash

# Create main directory structure
mkdir -p modules/network modules/compute files

# Create main.tf
cat > main.tf << 'EOF'
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

module "network" {
  source = "./modules/network"
  
  project_id = var.project_id
  region     = var.region
  network_name = var.network_name
}

module "compute" {
  source = "./modules/compute"
  
  project_id    = var.project_id
  region        = var.region
  zone          = var.zone
  instance_name = var.instance_name
  machine_type  = var.machine_type
  network_name  = module.network.network_name
  subnet_name   = module.network.subnet_name
}
EOF

# Create variables.tf
cat > variables.tf << 'EOF'
variable "credentials_file" {
  description = "Path to GCP credentials JSON file"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
}

variable "network_name" {
  description = "VPC Network Name"
  type        = string
}

variable "instance_name" {
  description = "VM Instance Name"
  type        = string
}

variable "machine_type" {
  description = "VM Machine Type"
  type        = string
}
EOF

# Create terraform.tfvars
cat > terraform.tfvars << 'EOF'
credentials_file = "path/to/your/credentials.json"
project_id       = "your-project-id"
region          = "us-central1"
zone            = "us-central1-a"
network_name    = "my-vpc-network"
instance_name   = "ubuntu-vm"
machine_type    = "e2-medium"
EOF

# Create network module files
# modules/network/main.tf
cat > modules/network/main.tf << 'EOF'
resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "allow_http_ssh" {
  name    = "${var.network_name}-allow-http-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
}
EOF

# modules/network/outputs.tf
cat > modules/network/outputs.tf << 'EOF'
output "network_name" {
  value = google_compute_network.vpc_network.name
}

output "subnet_name" {
  value = google_compute_subnetwork.subnet.name
}
EOF

# modules/network/variables.tf
cat > modules/network/variables.tf << 'EOF'
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "network_name" {
  description = "VPC Network Name"
  type        = string
}
EOF

# Create compute module files
# modules/compute/main.tf
cat > modules/compute/main.tf << 'EOF'
resource "google_compute_instance" "vm_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.subnet_name

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  provisioner "file" {
    source      = "files/"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }
}
EOF

# modules/compute/variables.tf
cat > modules/compute/variables.tf << 'EOF'
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
}

variable "instance_name" {
  description = "VM Instance Name"
  type        = string
}

variable "machine_type" {
  description = "VM Machine Type"
  type        = string
}

variable "network_name" {
  description = "VPC Network Name"
  type        = string
}

variable "subnet_name" {
  description = "Subnet Name"
  type        = string
}
EOF

# Make the script executable
chmod +x create_terraform_files.sh

echo "Terraform project structure has been created successfully!"
echo "Please make sure to:"
echo "1. Update terraform.tfvars with your specific values"
echo "2. Place your GCP credentials JSON file in the correct location"
echo "3. Ensure you have an SSH key pair generated"
echo "4. Place any files you want to copy to the VM in the 'files' directory"
EOF