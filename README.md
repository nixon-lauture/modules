# 🌐 Terraform GCP Infrastructure Modules

This repository provides a comprehensive set of **Terraform modules** for deploying **production-ready** infrastructure on **Google Cloud Platform (GCP)**. Each module is designed to be **modular**, **reusable**, and aligned with **GCP best practices** for scalability, security, and cost-efficiency.

## 📁 Repository Structure

```
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
```

## ✨ Key Features

- ✅ **Production-Ready** – Implements GCP best practices
- ✅ **Modular Design** – Plug-and-play modules for flexibility
- ✅ **Cost-Optimized** – Ideal for development and testing environments
- ✅ **Security-First** – Includes IAM roles, firewall rules, and secure defaults
- ✅ **Comprehensive** – Covers VPCs, serverless, containers, and AI/ML
- ✅ **Well-Documented** – Clear README and inline comments
- ✅ **Integration-Ready** – Modules work seamlessly together

## 🔍 Module Overview

### 📂 env/dev/ – Development Environment

Infrastructure scaffolding for development:

- **main.tf** – Invokes and configures infrastructure modules
- **variables.tf** – Input variables with dev-optimized defaults
- **outputs.tf** – Useful outputs for integrations and CI/CD
- **provider.tf** – GCP provider configuration
- **README.md** – Details about the dev setup

### 🌐 modules/vpc-network/ – VPC Network Module

Sets up secure and scalable networking:

- Creates VPCs, subnets, NAT, routes, and firewall rules
- Supports custom CIDRs and IP ranges

**Files:**
- **main.tf** – Core logic for network resources
- **variables.tf** – Input configurations (e.g., subnets, regions)
- **outputs.tf** – Exported network details (e.g., VPC name, subnet IDs)

### ⚙️ modules/cloud-functions/ – Cloud Functions Module

Deploys Gen 2 Cloud Functions with flexible triggers:

- Supports HTTP, Pub/Sub, Cloud Storage, and Scheduler triggers
- Custom IAM roles and environment variables

**Files:**
- **main.tf** – Function logic and trigger setup
- **variables.tf** – Function-level inputs
- **outputs.tf** – Function endpoint, name, and status

### 🐳 modules/cloud-run/ – Cloud Run Module

Deploys containerized applications on Cloud Run:

- Auto-scaling, traffic splitting, and IAM integration
- Configurable CPU, memory, and revision settings

**Files:**
- **main.tf** – Cloud Run deployment logic
- **variables.tf** – Container and service configurations
- **outputs.tf** – Service URL and metadata

### 🤖 modules/vertex-ai/ – Vertex AI Module

ML infrastructure for GCP Vertex AI:

- Deploys datasets, models, training jobs, and endpoints
- Permissions for notebooks, pipelines, and service accounts

**Files:**
- **main.tf** – Vertex AI resource creation
- **variables.tf** – Dataset/model/training configurations
- **outputs.tf** – Model IDs, endpoints, service accounts

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) configured
- GCP Project with billing enabled

### Basic Deployment

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd terraform-gcp-infrastructure
   ```

2. **Navigate to development environment**
   ```bash
   cd env/dev
   ```

3. **Configure variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your project settings
   ```

4. **Deploy infrastructure**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## 🔧 Usage Example

```hcl
# env/dev/main.tf
module "vpc_network" {
  source = "../../modules/vpc-network"
  
  project_id   = var.project_id
  region       = var.region
  environment  = "dev"
}

module "cloud_functions" {
  source = "../../modules/cloud-functions"
  
  project_id  = var.project_id
  region      = var.region
  environment = "dev"
  
  vpc_connector_name = module.vpc_network.vpc_connector_name
}

module "cloud_run" {
  source = "../../modules/cloud-run"
  
  project_id  = var.project_id
  region      = var.region
  environment = "dev"
  
  vpc_connector_name = module.vpc_network.vpc_connector_name
}

module "vertex_ai" {
  source = "../../modules/vertex-ai"
  
  project_id          = var.project_id
  region              = var.region
  environment         = "dev"
  
  model_bucket_name   = var.vertex_model_bucket_name
  staging_bucket_name = var.vertex_staging_bucket_name
  
  developer_principals = [
    "user:developer@company.com"
  ]
}
```

## 🛡️ Security & Best Practices

- **Network Isolation**: Private subnets with NAT for outbound access
- **IAM Controls**: Service accounts with minimal required permissions
- **Firewall Rules**: Restrictive ingress/egress configurations
- **Encryption**: At rest and in transit where applicable
- **Monitoring**: Cloud Operations integration with alerting

## 📊 Monitoring & Cost Management

- **Resource Labeling**: Consistent tagging for cost attribution
- **Auto-scaling**: Right-sized resources that scale with demand
- **Development Optimization**: Cost-effective configurations for dev/test
- **Monitoring Dashboards**: Built-in observability and alerting

## 🔄 CI/CD Integration

The modules support automated deployment workflows:

```yaml
# GitHub Actions example
name: Deploy Infrastructure
on:
  push:
    branches: [main]
    paths: ['env/dev/**']

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v1
    - name: Deploy
      run: |
        cd env/dev
        terraform init
        terraform plan
        terraform apply -auto-approve
```

## 🐛 Troubleshooting

### Common Issues

1. **API Not Enabled**
   ```bash
   gcloud services enable compute.googleapis.com
   gcloud services enable run.googleapis.com
   gcloud services enable aiplatform.googleapis.com
   ```

2. **Permissions Issues**
   ```bash
   gcloud auth application-default login
   gcloud config set project YOUR_PROJECT_ID
   ```

3. **Resource Quotas**
   ```bash
   gcloud compute project-info describe --project=PROJECT_ID
   ```

## 📚 Documentation

- [Development Environment Guide](env/dev/README.md)
- [Google Cloud Architecture Center](https://cloud.google.com/architecture)
- [Terraform GCP Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with proper testing
4. Update documentation
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

---

**Ready to get started?** Head over to the [development environment](env/dev/) to deploy your first infrastructure stack!
