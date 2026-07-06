# Environment Setup & Tool Stack

This document outlines the software versions and toolchain used for the KijaniKiosk DevOps infrastructure deployment.

| Tool | Version / Details |
| :--- | :--- |
| **Operating System** | Ubuntu 22.04.5 LTS (GNU/Linux 6.8.0-1060-aws) |
| **Terraform Core** | v1.9.0 |
| **Terraform Provider (AWS)** | hashicorp/aws v6.53.0 |
| **Ansible** | v2.16.2 |
| **Python** | 3.10.12 (for Ansible execution) |
| **AWS CLI** | aws-cli/2.15.0 |
| **Shell** | Bash 5.1.16 |

## Infrastructure Connectivity
- **Communication Protocol**: SSH (via custom key pair)
- **Deployment Strategy**: Automated CI/CD pipeline (`pipeline.sh` orchestrating Terraform and Ansible)
- **State Management**: Local state (for development/staging context)