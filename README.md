# AWS EKS Terraform Module for Lab or testing environments

This repository contains a Terraform module for deploying an Amazon EKS (Elastic Kubernetes Service) cluster with various add-ons and configurations. It's designed for labs or testing environments and follows AWS best practices.

[![Terraform](https://img.shields.io/badge/terraform-%23623CE4.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)

## Features

- **EKS Cluster Setup**

  - Configurable Kubernetes version
  - Public endpoint access with security controls
  - Cluster add-ons management
  - Support for various instance types

- **IAM Integration**

  - Role-based access control (RBAC)
  - Three access levels: Admin, Developer, and ReadOnly
  - IAM user management
  - Integration with AWS IAM

- **Networking**

  - Custom VPC creation
  - Public and private subnets
  - Security group management
  - VPC endpoints for AWS services

- **Add-ons Support**
  - AWS Load Balancer Controller
  - External DNS
  - Metrics Server
  - EBS CSI Driver
  - Node Autoscaling (Karpenter or Cluster Autoscaler)
  - Monitoring (Prometheus Stack or CloudWatch Observability)
  - EFS CSI Driver

## Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.7.0
- AWS CLI configured
- kubectl installed
- Basic understanding of:
  - Terraform
  - Kubernetes
  - AWS Services (EKS, VPC, IAM)

## Usage

1. Clone the repository:

```bash
git clone <repository-url>
cd eks-terraform-module
```

2. Initialize Terraform:

```bash
terraform init
```

3. Configure your variables by creating a `terraform.tfvars` file:

```hcl
environment     = "dev"
cluster_name    = "my-eks-cluster"
cluster_version = "1.32"
vpc_cidr        = "10.0.0.0/16"
```

4. Review and apply the configuration:

```bash
terraform plan
terraform apply
```

## Module Structure

```
.
├── versions.tf            # Provider and version constraints
├── main.tf                # Main configuration and locals
├── variables.tf           # Input variables
├── outputs.tf             # Output values
├── vpc.tf                 # VPC configuration
├── iam-roles.tf           # IAM roles for cluster access
├── iam-users.tf           # IAM users management
├── eks-cluster.tf         # EKS cluster configuration
├── karpenter.tf           # Karpenter autoscaler
├── cluster-autoscaler.tf  # Cluster Autoscaler
├── alb-controller.tf      # AWS Load Balancer Controller
├── external-dns.tf        # External DNS
├── metrics-server.tf      # Metrics Server
├── policies/              # IAM policy JSON files
│   ├── aws-load-balancer-controller-policy.json
│   └── external-dns-policy.json
└── examples/              # Example configurations
    └── basic-usage/       # Basic cluster setup
```

## Important Variables

| Name                      | Description                       | Type   | Default            |
| ------------------------- | --------------------------------- | ------ | ------------------ |
| cluster_name              | Name of the EKS cluster           | string | "test-eks-cluster" |
| environment               | Environment name                  | string | "dev"              |
| cluster_version           | Kubernetes version                | string | "1.32"             |
| vpc_cidr                  | CIDR block for VPC                | string | "10.0.0.0/16"      |
| enable_karpenter          | Enable Karpenter node provisioner | bool   | false              |
| enable_cluster_autoscaler | Enable Cluster Autoscaler         | bool   | false              |
| enable_metrics_server     | Enable metrics server             | bool   | true               |

## Add-ons Configuration

### Node Autoscaling

You can choose between two autoscaling solutions, but you cannot enable both simultaneously:

#### Karpenter

Enables modern and efficient node provisioning:

```hcl
enable_karpenter = true
enable_cluster_autoscaler = false  # Must be false when Karpenter is enabled
```

#### Cluster Autoscaler

Traditional node group scaling:

```hcl
enable_cluster_autoscaler = true
enable_karpenter = false  # Must be false when Cluster Autoscaler is enabled
```

### Load Balancer Controller

For managing AWS Application Load Balancers:

```hcl
enable_load_balancer_controller = true
```

### External DNS

For automatic DNS management:

```hcl
enable_external_dns = true
```

## IAM Role Configuration

The module creates three types of IAM roles:

- **Admin**: Full cluster management permissions
- **Developer**: Limited to specific namespaces
- **ReadOnly**: View-only access to cluster resources

To create users with these roles:

```hcl
create_admin_users     = true
admin_users           = ["admin1", "admin2"]
create_developer_users = true
developer_users       = ["dev1", "dev2"]
```

## Best Practices Implemented

1. **Code Organization**

   - Thematic file separation for better navigation
   - Logical grouping of related resources
   - Clear separation of concerns

2. **Security**

   - Private subnet usage for worker nodes
   - RBAC implementation
   - Least privilege principle in IAM roles
   - Security group restrictions

3. **Scalability**

   - Choice between Karpenter or Cluster Autoscaler for node scaling
   - Support for multiple node groups
   - Configurable auto-scaling settings

4. **Maintainability**

   - Consistent variable naming
   - Consistent tagging
   - Validation checks to prevent conflicting configurations
   - Clear variable organization
   - Comprehensive documentation

5. **Monitoring**
   - Metrics Server integration
   - CloudWatch logging
   - Control plane logging

## Note

This module is designed for lab or testing environments. While it implements best practices, you should review and adjust the security configurations before using it in a production environment.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
