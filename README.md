# AWS DevOps Engineer Skill Test Solution

This repository contains a comprehensive solution for the AWS DevOps Engineer Skill Test, focusing on designing, provisioning, securing, deploying, monitoring, and optimizing a complete AWS-native infrastructure. It also demonstrates integration with Google Gemini for code quality and security checks within a CI/CD pipeline.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Infrastructure as Code (IaC)](#infrastructure-as-code-iac)
    - [2.1 Prerequisites](#21-prerequisites)
    - [2.2 Terraform Setup & Deployment](#22-terraform-setup--deployment)
3. [CI/CD Pipeline](#cicd-pipeline)
    - [3.1 Application Microservice](#31-application-microservice)
    - [3.2 GitHub Actions Workflow](#32-github-actions-workflow)
    - [3.3 Running Tests](#33-running-tests)
4. [Monitoring, Logging & Alerting](#monitoring-logging--alerting)
    - [4.1 CloudWatch Dashboard](#41-cloudwatch-dashboard)
    - [4.2 Logs and PII Stripping](#42-logs-and-pii-stripping)
    - [4.3 CloudWatch Alarms](#43-cloudwatch-alarms)
5. [Security & Compliance](#security--compliance)
    - [5.1 GuardDuty & AWS Config Rules](#51-guardduty--aws-config-rules)
    - [5.2 Secrets Management](#52-secrets-management)
    - [5.3 Gemini Integration](#53-gemini-integration)

---

## Architecture Overview

This solution deploys a highly available, secure, and observable web application on **AWS Fargate (ECS)** backed by **PostgreSQL (RDS)** and **Redis (ElastiCache)**. The infrastructure is provisioned using **Terraform**, and the application deployment is automated via a **GitHub Actions CI/CD pipeline** that includes code quality, security scans, and PII stripping for logs.

**Key components include:**

- **Networking:** VPC across two AZs with public, private, and database subnets, Internet Gateway, NAT Gateway.
- **Compute:** ECS Cluster with Fargate Launch Type for the application microservice, fronted by an Application Load Balancer (ALB).
- **Data Storage:** Multi-AZ PostgreSQL RDS instance (with read replica), Redis ElastiCache cluster, S3 buckets for static assets and Terraform state.
- **Security:** IAM roles with least privilege, granular Security Groups, KMS encryption for RDS, S3, ElastiCache, SSM Parameter Store for secrets, GuardDuty, and AWS Config Rules.
- **Observability:** Centralized CloudWatch Logs (with PII stripping Lambda), CloudWatch Alarms, and a comprehensive CloudWatch Dashboard.
- **CI/CD:** GitHub Actions pipeline for automated build, test (unit, linting, Terraform validate), security scanning (Gemini), Docker image push to ECR, and zero-downtime deployment to ECS.

[Link to Architecture Diagram (Mermaid Diagram)](Link)

---

## Infrastructure as Code (IaC)

All infrastructure is defined as code using **Terraform**, structured into reusable modules for maintainability and scalability.

### 2.1 Prerequisites

- AWS Account with appropriate permissions.
- Terraform CLI (v1.x.x or higher) installed.
- AWS CLI configured with credentials.
- npm (Node Package Manager) installed for application dependencies.
- GitHub repository where this code is hosted.

### 2.2 Terraform Setup & Deployment

1. **Clone the Repository:**

    ```bash
    git clone https://github.com/Dexarc/pente-ai-devops.git
    cd pente-ai-devops
    ```

2. **Configure Terraform Backend (S3):**

    Ensure your `infra/dev/main.tf` is configured to use an S3 backend for Terraform state. **Note:** The S3 bucket for Terraform state must be created manually once or via a separate Terraform root before running this main configuration.

3. **Prepare Lambda Code (PII Stripper):**

    The PII stripping Lambda function code needs to be packaged:

    ```bash
    cd infra/dev/lambda_function/
    npm install # Install aws-sdk and other dependencies if any are explicitly used in Lambda
    zip -r pii_stripper.zip .
    cd ../../.. # Go back to the repository root
    ```

4. **Set Terraform Variables:**

    Update `infra/dev/terraform.tfvars` with your specific values, especially `alert_email` and `lambda_code_zip_path` (ensure this path is correct: `"lambda_function/pii_stripper.zip"` relative to `infra/dev/` or `../../infra/dev/lambda_function/pii_stripper.zip` if relative to modules).

5. **Initialize Terraform:**

    Navigate to the root module directory and initialize Terraform.

    ```bash
    cd infra/dev
    terraform init -upgrade
    ```

6. **Review and Apply Infrastructure:**

    Review the planned infrastructure changes and apply them.

    ```bash
    terraform plan -out=tfplan.out
    terraform apply "tfplan.out"
    ```

    This will provision your VPC, subnets, ALB, ECS cluster/service, RDS, ElastiCache, S3 buckets, IAM roles, KMS keys, GuardDuty, AWS Config Rules, CloudWatch Log Groups, Alarms, Dashboard, and the PII stripping Lambda.

---

## CI/CD Pipeline

The CI/CD pipeline is implemented using **GitHub Actions**, ensuring automated builds, tests, security scans, and deployments.

### 3.1 Application Microservice

The application is a simple **Node.js "hello-world" microservice** (`app/server.js`) that connects to PostgreSQL and fetches a greeting, reading its database connection parameters (username, password) from AWS SSM Parameter Store. It includes a **Dockerfile** for containerization.

### 3.2 GitHub Actions Workflow

The CI/CD workflow is defined in `.github/workflows/ci-cd.yml`. AWS credentials for the pipeline are managed securely as **GitHub Secrets**.

**On Pull Request to main:**

- Checks out code.
- Installs Node.js dependencies (`npm install`).
- Runs unit tests (`npm test`).
- Runs code linting (`npm run lint` - if configured).
- Performs Terraform formatting check (`terraform fmt -check=true`).
- Runs Terraform validation (`terraform validate`).
- **Google Gemini Code Scan:** (this is a dedicated step that invokes Gemini API for security analysis of IaC and/or application code, generating a report).

- Builds Docker image.
- Authenticates to Amazon ECR.
- Pushes Docker image to the ECR repository.

- Generates terraform plan against the infra/env directory and saves the plan.
- Applies the terraform plan to ensure all core AWS components are updated and in place.

- Deploys the new image to the ECS Fargate service with a zero-downtime rolling update.

### 3.3 Running Tests (Locally)

To run the application's unit tests locally:

1. Navigate to the application directory:

    ```bash
    cd app
    ```

2. Install dependencies:

    ```bash
    npm install
    ```

3. Run unit tests:

    ```bash
    npm test
    ```

This will execute the tests defined in `app/tests/server.test.js`.

---

## Monitoring, Logging & Alerting

Comprehensive observability is achieved through **AWS CloudWatch**.

### 4.1 CloudWatch Dashboard

A **CloudWatch Dashboard** (`pente-dev-dashboard`) is provisioned via Terraform, providing a centralized view the application's health.

#### How to View:

- Go to the **AWS CloudWatch Console**.
- In the left navigation, click **"Dashboards"**.
- Select the dashboard named **pente-dev-dashboard**.

#### Contents:

- ECS Service CPU and Memory Utilization.
- RDS Instance CPU Utilization and Database Connections.
- ALB Request Count, 5XX Errors, and Target Connection Errors.
- Sanitized Application Logs: Displays logs from the PII-stripped log group.
- RDS Read Replica Lag (if read replica is enabled).

### 4.2 Logs and PII Stripping

**Log Centralization:** Application logs from ECS tasks are automatically sent to CloudWatch Logs (`log group: /ecs/pente-dev-app`).

**PII Stripping:** A CloudWatch Logs Subscription Filter forwards these raw logs to an AWS Lambda function (`pente-dev-pii-stripper`). This Lambda processes the logs, redacting common PII (e.g., emails, phone numbers), and then sends the sanitized logs to a separate log group (`/ecs/pente-dev-app-sanitized`). The dashboard displays logs from this sanitized group.

### 4.3 CloudWatch Alarms

CloudWatch Alarms are configured to proactively notify of potential issues:

- **ECS Service:** CPU Utilization > 80%, Memory Utilization > 80%.
- **RDS Instance:** CPU Utilization > 70%.
- **ALB:** HTTP 5xx Error Rate > 5%.

All alarms send notifications to an **SNS topic**, which then emails to the configured and subscribed `alert_email`.

---

## Security & Compliance

Security is a core consideration, implemented with **AWS GuardDuty**, **AWS Config**, and **Secure Secrets Management**.

### 5.1 GuardDuty & AWS Config Rules

- **AWS GuardDuty:** Enabled for continuous threat detection across the AWS account.
- **AWS Config Rules:** Three critical AWS Config rules are implemented to enforce compliance:
    - **EC2_SECURITY_GROUP_OPEN_TO_ALL:** Checks for security groups allowing unrestricted inbound access.
    - **S3_BUCKET_ENCRYPTED_WITH_KMS:** Ensures S3 buckets are encrypted with KMS.
    - **RDS_STORAGE_ENCRYPTED:** Verifies RDS instances have storage encryption enabled.

### 5.2 Secrets Management

Application secrets, such as the RDS database username and password, are securely stored as **SecureString parameters** in AWS **SSM Parameter Store** and retrieved by the ECS application at runtime using IAM role permissions. **KMS** keys are used for encryption at rest.

### 5.3 Gemini Integration

**Automated Code Scan:** A step in the GitHub Actions CI/CD workflow will invoke the **Google Gemini API** (using a mock or test key) to scan the Terraform code for security misconfigurations and best practices.

**Security Report:** Gemini's analysis will generate a **Markdown-formatted "security report"** that can be posted as a pull request comment (simulated via `echo` or a more advanced GitHub Action).

---

