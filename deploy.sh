#!/bin/bash

# Set error handling
set -e

echo "Starting deployment process..."

# Change to Terraform directory and initialize
cd terraform
echo "Initializing Terraform..."
terraform init

# Apply Terraform configuration
echo "Planning Terraform configuration..."
terraform plan -out=tfplan

echo "Applying Terraform configuration..."
terraform apply tfplan

# Get the VM's FQDN and credentials
echo "Getting VM details..."
VM_FQDN=$(terraform output -raw public_fqdn)
ADMIN_USER=$(grep admin_username terraform.tfvars | cut -d'=' -f2 | tr -d ' "')
ADMIN_PASS=$(grep admin_password terraform.tfvars | cut -d'=' -f2 | tr -d ' "')

# Wait for VM to be ready
echo "Waiting for VM to be fully provisioned (60 seconds)..."
sleep 60

# Create Ansible inventory file
cd ../ansible
echo "Creating Ansible inventory file..."
cat > inventory/hosts.ini << EOF
[eveng]
$VM_FQDN ansible_user=$ADMIN_USER ansible_password=$ADMIN_PASS ansible_become_pass=$ADMIN_PASS ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

# Run Ansible playbook
echo "Running Ansible playbook..."
ansible-playbook -i inventory/hosts.ini install-pnetlab.yml --verbose

echo "Deployment completed!"
echo "EVE-NG will be available at: http://$VM_FQDN"
echo "SSH access: ssh $ADMIN_USER@$VM_FQDN"
echo "Default EVE-NG credentials:"
echo "Username: admin"
echo "Password: eve"