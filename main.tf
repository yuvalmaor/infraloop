terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
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