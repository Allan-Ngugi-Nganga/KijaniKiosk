#!/bin/bash
set -e

echo "--- Phase 1: Terraform ---"
cd terraform
terraform init
terraform apply -auto-approve

echo "--- Phase 2: Inventory Generation ---"
# This uses jq to parse the output into Ansible inventory format
echo "[kijanikiosk]" > ../ansible/inventory.ini
terraform output -json | jq -r '.server_ips.value | to_entries | .[] | .key + "-staging ansible_host=" + .value + " ansible_user=ubuntu"' >> ../ansible/inventory.ini

echo "--- Phase 3: Ansible ---"
cd ../ansible
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i inventory.ini kijanikiosk.yml --private-key ~/.ssh/kijanikiosk-key.pem

echo "Pipeline complete."