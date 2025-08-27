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
