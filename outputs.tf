output "vm_public_ip" {
  description = "Public IP address of the VM instance"
  value       = module.compute.instance_public_ip
}