resource "random_id" "instance_id" {
  byte_length = 4
  keepers = {
    timestamp = timestamp()
  }
}

resource "google_compute_instance" "vm_instance" {
  name         = "${var.instance_name}-${random_id.instance_id.hex}"
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
      # Empty access_config block will generate a new ephemeral IP each time
    }
  }

  metadata = {
    ssh-keys = "yuvalnix305:${file("~/.ssh/id_rsa.pub")}"
  }
   # Wait for instance to be ready before copying files
  provisioner "remote-exec" {
    inline = ["echo 'Instance is ready'"]

    connection {
      type        = "ssh"
      user        = "yuvalnix305"
      private_key = file("~/.ssh/id_rsa")
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  # Copy the files directory
  provisioner "file" {
    source      = "./files"
    destination = "/home/yuvalnix305"

    connection {
      type        = "ssh"
      user        = "yuvalnix305"
      private_key = file("~/.ssh/id_rsa")
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  # Make scripts executable
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/yuvalnix305/files/*.sh",
      "chmod +x /home/yuvalnix305/files/*.py",
      "sudo mv /home/yuvalnix305/files/* /home/yuvalnix305/",
      "rm -r /home/yuvalnix305/files"
    ]

    connection {
      type        = "ssh"
      user        = "yuvalnix305"
      private_key = file("~/.ssh/id_rsa")
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }
}
