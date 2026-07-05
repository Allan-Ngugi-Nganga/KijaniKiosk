# KijaniKiosk API Server - Desired State Specification

## Identity
- Name: kijanikiosk-api-staging
- Environment tag: staging
- Owner tag: amina

## Compute
- Provider: Multipass (Local Virtualization)
- Region: Local
- Instance type: 1 CPU, 1GB RAM
- Operating system: ubuntu-22.04-lts (exact image ID: N/A for Multipass)

## Networking
- VPC: Default (Multipass Bridge)
- Subnet: Default
- Assign public IP: no

## Access Control
- SSH access: port 22, source 127.0.0.1/32 (Localhost) only
- HTTP access: port 80, source 0.0.0.0/0
- All other inbound: deny
- All outbound: allow

## Storage
- Root volume: 5GB, type standard

## Authentication
- SSH key pair name: multipass-default

## What must NOT exist on this server after provisioning
- No default password authentication
- No services listening other than sshd
- No world-writable directories outside /tmp

## Open questions (things that will need decisions before Terraform can encode this)
- How will Terraform map the networking differences between a local Multipass VM and a standard AWS/GCP VPC? 
- What specific Terraform provider is needed to target a local Multipass instance instead of a cloud provider?

## Hardest Decision and Why
The hardest decision during the manual provisioning process was determining how to properly translate cloud-specific concepts like VPCs, Subnets, and Security Groups into a local Multipass environment. Because Multipass abstracts away the heavy lifting of network configuration to instantly provide a functional VM, it felt like I was skipping decisions about inbound/outbound firewall rules that are explicitly required in the constraints. I am least certain about how strictly to define these local networking defaults in the declarative spec, as the automation step on Tuesday will likely require a much more rigid and explicit security group definition if migrated to a true cloud provider.