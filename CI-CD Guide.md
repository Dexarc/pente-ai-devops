
# CI/CD Pipeline Demo Guide (Full Cycle on Pull Request)

This guide provides a brief walkthrough on how to trigger and observe the GitHub Actions CI/CD pipeline for the pente-ai-devops application. As configured, this pipeline executes the full build, test, scan, and deployment cycle upon a Pull Request to the main branch.

## Prerequisites

Before proceeding, ensure the following:

- You have a fork or clone of the pente-ai-devops repository.
- You have necessary AWS credentials configured as GitHub Secrets in your repository:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION` (e.g., `us-east-1`)
- Your ECR repository (e.g., `hello-world-pente-repo`) is created, as the workflow requires it.

## Triggering the Pipeline

This CI/CD workflow (`.github/workflows/ci-cd.yml`) is configured to run on a Pull Request (PR) event targeting the main branch. This single trigger will initiate all steps, from code validation to infrastructure application and application deployment.

### Step 1: Make a Code Change (Feature Branch)

Navigate to your application directory (`app/`) or infrastructure directory (`infra/`) and make a small, non-breaking change. For example, update a comment in `app/server.js` or `infra/dev/main.tf`.

```bash
# From your repository root
cd app/
# Open server.js in your preferred editor, e.g.:
# nano server.js
# Make a small, safe change, like updating a console.log message or adding a comment.
```

### Step 2: Commit Changes to a New Feature Branch

It's essential to work on a feature branch for changes that will trigger a Pull Request.

```bash
# From your repository root
git checkout -b feature/demo-full-pipeline
git add . # Add all modified/new files
git commit -m "feat: Trigger full CI/CD pipeline via PR demo"
git push origin feature/demo-full-pipeline
```

### Step 3: Create a Pull Request (Triggers Full CI/CD Workflow)

Go to your GitHub repository in your web browser. GitHub will typically prompt you to create a Pull Request from your `feature/demo-full-pipeline` branch to the `main` branch.

- Click "Compare & pull request".
- Add a title and description (e.g., "Demo: Full CI/CD pipeline triggered by PR").
- Click "Create pull request".

### Observe the Full CI/CD Workflow

Immediately navigate to the "Actions" tab in your GitHub repository. You should see a new workflow run initiated, corresponding to your newly created Pull Request.

Monitor its progress. This single job will execute all phases:

- Checkout code
- Setup Node.js, Install Node.js dependencies, Run ESLint (Linting), Run Unit Tests
- Configure AWS Credentials
- Setup Terraform, Terraform Format Check, Terraform Init, Terraform Validate
- Get the Commit SHA
- Ensure ECR Repository Exists
- Login to Amazon ECR
- Build Docker image
- Push Docker image
- Google Gemini Security Scan - This step will output its security analysis.
- Terraform Plan
- Terraform Apply (This will apply your infrastructure changes)
- Deploy to ECS (Zero-downtime Rolling Update) (This will update your application on Fargate)

Review the output of each step. Pay close attention to the test results, Terraform output, Gemini scan report, and the successful completion of the deployment steps.

### Step 4: Verify Deployment

After the workflow run completes successfully:

1. **Access your Application:** Navigate to the URL of your Application Load Balancer (ALB) to confirm the updated application is running. You should see your changes reflected.
2. **Check ECS Console:** Go to the AWS ECS Console, navigate to your cluster, and then your service. You should see a new deployment revision active.
3. **Check CloudWatch Logs:** Verify new application logs are flowing into your `/ecs/pente-dev-app` and `/ecs/pente-dev-app-sanitized` log groups.
4. **Check CloudWatch Dashboard:** Observe your `pente-dev-dashboard` for updated metrics and logs.

This process demonstrates the automated full CI/CD flow from a Pull Request, encompassing code validation, infrastructure changes, and application deployment.