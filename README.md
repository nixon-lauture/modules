# 🌐 Terraform GCP Infrastructure Modules

This repository provides a comprehensive set of **Terraform modules** for deploying **production-ready** infrastructure on **Google Cloud Platform (GCP)**. Each module is designed to be **modular**, **reusable**, and aligned with **GCP best practices** for scalability, security, and cost-efficiency.

---

## 📦 Repository Structure

```plaintext
.
├── env/dev/                    # Development environment setup
│   ├── main.tf                 # Orchestrates modules with dev-specific settings
│   ├── variables.tf            # Input variables for development
│   ├── outputs.tf              # Outputs for development integration
│   ├── provider.tf             # GCP provider configuration
│   └── README.md               # Documentation for the dev environment
├── modules/                    # Reusable infrastructure modules
│   ├── vpc-network/            # VPC networking module
│   ├── cloud-functions/        # Cloud Functions (Gen 2) module
│   ├── cloud-run/              # Cloud Run container services module
│   └── vertex-ai/              # Vertex AI module for ML workloads
└── README.md                   # Root documentation (this file)

Key Features

✅ Production-Ready: Implements GCP best practices

✅ Modular Design: Plug-and-play modules for flexibility

✅ Cost-Optimized: Ideal for development and testing environments

✅ Security-First: Includes IAM roles, firewall rules, and secure defaults

✅ Comprehensive Coverage: From VPCs to serverless to AI/ML

✅ Well-Documented: Each module includes usage instructions and examples

✅ Integration-Ready: Modules work seamlessly together

📁 Module Overview
env/dev/ – Development Environment

Infrastructure scaffolding for development:

main.tf – Invokes and configures infrastructure modules

variables.tf – Input variables with dev-optimized defaults

outputs.tf – Useful outputs for integrations and CI/CD

provider.tf – GCP provider configuration

README.md – Details about the dev setup

modules/vpc-network/ – VPC Network Module

Sets up secure and scalable networking:

Creates VPCs, subnets, NAT, routes, and firewall rules

Supports custom CIDRs and IP ranges

Files:

main.tf – Core logic for network resources

variables.tf – Input configurations (e.g., subnets, regions)

outputs.tf – Exported network details (e.g., VPC name, subnet IDs)

modules/cloud-functions/ – Cloud Functions Module

Deploys Gen 2 Cloud Functions with flexible triggers:

Supports HTTP, Pub/Sub, Cloud Storage, and Scheduler triggers

Enables custom IAM and environment settings

Files:

main.tf – Function logic and trigger setup

variables.tf – Function-level inputs

outputs.tf – Function endpoint, name, and status

modules/cloud-run/ – Cloud Run Module

Deploys containerized apps on serverless Cloud Run:

Auto-scaling, traffic splitting, and IAM integration

Configurable CPU/memory settings and revision controls

Files:

main.tf – Cloud Run deployment logic

variables.tf – Container and service configurations

outputs.tf – Service URL and metadata

modules/vertex-ai/ – Vertex AI Module

Builds infrastructure for AI/ML workflows on GCP:

Deploys datasets, models, training jobs, and endpoints

Includes permissions for notebooks, pipelines, and training

Files:

main.tf – Vertex AI resource deployment

variables.tf – Model/dataset/training configurations

outputs.tf – Model IDs, endpoints, and service accounts
