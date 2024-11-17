#!/usr/bin/env python3
import subprocess
import json
import time
import paramiko
import sys
import requests
import random  # Added random import

class TerraformAutomation:
    def __init__(self):
        self.ssh_username = "yuvalnix305"
        self.private_key_path = "~/.ssh/id_rsa"
    def __init__(self):
        self.ssh_username = "yuvalnix305"
        self.private_key_path = "~/.ssh/id_rsa"
        # List of GCP regions and their zones
        self.regions = [
            {"region": "me-west1", "zone": "me-west1-c"},
            {"region": "me-west1", "zone": "me-west1-b"},
            {"region": "me-west1", "zone": "me-west1-a"},      # Israel
            {"region": "us-central1", "zone": "us-central1-a"},
            {"region": "europe-west4", "zone": "europe-west4-a"},
            {"region": "asia-southeast1", "zone": "asia-southeast1-a"},
            {"region": "australia-southeast1", "zone": "australia-southeast1-a"},
            {"region": "southamerica-east1", "zone": "southamerica-east1-a"},
            {"region": "asia-east1", "zone": "asia-east1-a"},
            {"region": "us-west1", "zone": "us-west1-a"},
            {"region": "europe-west1", "zone": "europe-west1-b"},
            {"region": "asia-northeast1", "zone": "asia-northeast1-a"}
        ]

    def update_tfvars(self):
        """Update terraform.tfvars with random region"""
        location = random.choice(self.regions)
        print(f"\nSelected location: ")
        print(f"Region: {location['region']}")
        print(f"Zone: {location['zone']}\n")
        
        tfvars_content = f'''project_id     = "third-diorama-440916-u8"
        region         = "{location["region"]}"
        zone           = "{location["zone"]}"
        network_name   = "my-vpc-network"
        instance_name  = "ubuntu-vm"
        machine_type   = "e2-medium"
        '''
        with open('terraform.tfvars', 'w') as f:
            f.write(tfvars_content)
    def run_command(self, command, shell=False):
        """Run a shell command and return output"""
        try:
            result = subprocess.run(
                command,
                shell=shell,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            return result.stdout
        except subprocess.CalledProcessError as e:
            print(f"Error executing command: {command}")
            print(f"Error output: {e.stderr}")
            sys.exit(1)

    def terraform_apply(self):
        """Run terraform apply with auto-approve"""
        print("Applying Terraform configuration...")
        self.run_command(["terraform", "apply", "-auto-approve"])
        print("Terraform apply completed successfully")

    def get_instance_ip(self):
        """Get the instance IP from terraform output"""
        print("Getting instance IP...")
        output = self.run_command(["terraform", "output", "-json", "vm_public_ip"])
        ip = json.loads(output)
        if isinstance(ip, dict) and 'value' in ip:
            ip = ip['value']
        return ip.strip('"')

    def run_remote_script(self, ip_address):
        """SSH into the instance and run the script"""
        print(f"Connecting to {ip_address}...")
        
        # Initialize SSH client
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        # Expand the private key path
        expanded_key_path = subprocess.getoutput(f'echo {self.private_key_path}')
        
        try:
            # Wait for SSH to become available
            max_attempts = 30
            for attempt in range(max_attempts):
                try:
                    ssh.connect(
                        ip_address,
                        username=self.ssh_username,
                        key_filename=expanded_key_path,
                        timeout=5
                    )
                    break
                except (paramiko.ssh_exception.NoValidConnectionsError, 
                        paramiko.ssh_exception.SSHException):
                    if attempt == max_attempts - 1:
                        raise
                    print(f"Waiting for SSH to become available... ({attempt + 1}/{max_attempts})")
                    time.sleep(10)

            print("Connected to instance. Running setup script...")
            
            # Run setup script
            stdin, stdout, stderr = ssh.exec_command('sudo bash ~/setup.sh')
            
            # Print output in real-time
            while True:
                line = stdout.readline()
                if not line:
                    break
                print(line.strip())
            
            # Check for errors
            stderr_output = stderr.read().decode()
            if stderr_output:
                print(f"Error output: {stderr_output}")
            
            # Get exit status
            exit_status = stdout.channel.recv_exit_status()
            if exit_status != 0:
                raise Exception(f"Setup script failed with exit status {exit_status}")

            print("Setup completed. Starting task script...")
            
            # Run task.py in background
            stdin, stdout, stderr = ssh.exec_command('sudo python3 ~/task.py &')
            
            # Wait for task completion by monitoring nginx page
            print("Monitoring task completion...")
            max_attempts = 60  # 5 minutes maximum wait time
            for attempt in range(max_attempts):
                try:
                    response = requests.get(f'http://{ip_address}')
                    content = response.text.strip()
                    print(f"Current status: {content}")
                    
                    if content == 'complete':
                        print("Task completed successfully!")
                        break
                        
                    if attempt == max_attempts - 1:
                        raise Exception("Task timed out")
                        
                except requests.RequestException:
                    print(f"Waiting for service... ({attempt + 1}/{max_attempts})")
                
                time.sleep(5)  # Check every 5 seconds

        finally:
            ssh.close()

    def terraform_destroy(self):
        """Run terraform destroy"""
        print("Destroying infrastructure...")
        self.run_command(["terraform", "destroy", "-auto-approve"])
        print("Infrastructure destroyed successfully")

    def download_output_file(self, ip_address):
        """Download output.txt from the remote server"""
        print("Downloading output.txt from server...")
        
        # Initialize SSH client
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        try:
            # Connect to the server
            expanded_key_path = subprocess.getoutput(f'echo {self.private_key_path}')
            ssh.connect(
                ip_address,
                username=self.ssh_username,
                key_filename=expanded_key_path
            )
            
            # Create SFTP client
            sftp = ssh.open_sftp()
            
            # Download the file
            try:
                sftp.get('/home/yuvalnix305/output.txt', './output.txt')
                print("File downloaded successfully")
            except FileNotFoundError:
                print("Warning: output.txt not found on server")
            except Exception as e:
                print(f"Error downloading file: {str(e)}")
                
        finally:
            if 'sftp' in locals():
                sftp.close()
            ssh.close()

    def run(self):
        """Run the full automation sequence"""
        try:
            print("Starting infrastructure deployment and script execution...")
            
            # Apply Terraform
            self.terraform_apply()
            
            # Get instance IP
            ip_address = self.get_instance_ip()
            print(f"Instance IP: {ip_address}")
            
            # Give instance some time to fully boot
            print("Waiting 30 seconds for instance to fully boot...")
            time.sleep(30)
            
            # Run remote scripts and monitor
            self.run_remote_script(ip_address)
            print(f"Instance IP: {ip_address}")
            # Download output file before destroying
            self.download_output_file(ip_address)
            print(f"Instance IP: {ip_address}")
            time.sleep(30)
            # Destroy infrastructure
            self.terraform_destroy()
            self.update_tfvars()
            print("Automation completed successfully!")
            
        except Exception as e:
            print(f"Error occurred: {str(e)}")
            print("Attempting to destroy infrastructure...")
            try:
                self.terraform_destroy()
            except Exception as destroy_error:
                print(f"Error during cleanup: {str(destroy_error)}")
            sys.exit(1)

if __name__ == "__main__":
    automation = TerraformAutomation()
    automation.run()