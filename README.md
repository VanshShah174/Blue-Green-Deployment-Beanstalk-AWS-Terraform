# AWS Elastic Beanstalk Blue/Green Deployment with Terraform

This project demonstrates a **Blue/Green deployment strategy** using AWS Elastic Beanstalk and Terraform. It creates two identical environments (Blue and Green) that allow for zero-downtime deployments by swapping traffic between them.

## 🏗️ Architecture Overview

![Blue/Green Deployment Architecture](Blue-Green-Deployment.png)

```
┌─────────────────┐    ┌─────────────────┐
│  Blue Environment │    │ Green Environment│
│   (Production)    │    │   (Staging)     │
│    Version 1.0    │◄──►│   Version 2.0   │
└─────────────────┘    └─────────────────┘
         │                       │
         └───────────┬───────────┘
                     │
            ┌─────────────────┐
            │   S3 Bucket     │
            │ (App Versions)  │
            └─────────────────┘
```

## 📋 Prerequisites

- **AWS CLI** configured with appropriate permissions
- **Terraform** >= 1.0
- **Node.js** application (sample apps included)
- **PowerShell** (Windows) or **Bash** (Linux/Mac) for packaging scripts

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd Day-17
```

### 2. Configure Variables

Create a `terraform.tfvars` file:

```hcl
aws_region = "us-east-1"
app_name = "my-app-bluegreen"
solution_stack_name = "64bit Amazon Linux 2023 v6.7.2 running Node.js 20"
instance_type = "t3.micro"

tags = {
  Project     = "BlueGreenDeployment"
  Environment = "Demo"
  ManagedBy   = "Terraform"
  Owner       = "YourName"
}
```

### 3. Package Applications

**Windows:**
```powershell
.\package-apps.ps1
```

**Linux/Mac:**
```bash
chmod +x package-apps.sh
./package-apps.sh
```

### 4. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

## 📁 Project Structure

```
Day-17/
├── app-v1/                    # Blue environment application (v1.0)
│   ├── app.js
│   ├── package.json
│   └── app-v1.zip
├── app-v2/                    # Green environment application (v2.0)
│   ├── app.js
│   ├── package.json
│   └── app-v2.zip
├── main.tf                    # Core infrastructure (IAM, S3, EB App)
├── blue-environment.tf        # Blue environment configuration
├── green-envrionment.tf       # Green environment configuration
├── provider.tf                # AWS provider configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output values and instructions
├── data-sources.tf            # Data sources for solution stacks
├── package-apps.ps1           # Windows packaging script
├── package-apps.sh            # Linux/Mac packaging script
├── terraform.tfvars           # Variable values (not in git)
├── .gitignore                 # Git ignore rules
└── README.md                  # This file
```

## 🔧 Infrastructure Components

### Core Resources
- **Elastic Beanstalk Application**: Container for environments
- **S3 Bucket**: Stores application versions
- **IAM Roles**: EC2 and service roles with proper permissions

### Blue Environment (Production)
- **Environment Name**: `{app_name}-blue`
- **Version**: 1.0
- **Application**: Simple Node.js app showing "Blue Environment - Version 1.0"

### Green Environment (Staging)
- **Environment Name**: `{app_name}-green`
- **Version**: 2.0
- **Application**: Simple Node.js app showing "Green Environment - Version 2.0"

## 🔄 Blue/Green Deployment Process

### Step 1: Verify Environments

After deployment, check both environments:

```bash
# Get environment URLs
terraform output blue_environment_url
terraform output green_environment_url
```

### Step 2: Test Applications

- **Blue Environment**: Should display "Blue Environment - Version 1.0"
- **Green Environment**: Should display "Green Environment - Version 2.0"

### Step 3: Perform Environment Swap

Use the AWS CLI to swap environment CNAMEs:

```bash
# Get the swap command
terraform output swap_command

# Execute the swap
aws elasticbeanstalk swap-environment-cnames \
  --source-environment-name my-app-bluegreen-blue \
  --destination-environment-name my-app-bluegreen-green \
  --region us-east-1
```

### Step 4: Verify Swap

After the swap (takes 1-2 minutes):
- **Blue URL** now shows Version 2.0
- **Green URL** now shows Version 1.0

### Step 5: Rollback (if needed)

Simply run the same swap command again to revert!

## 📊 Monitoring and Management

### Environment Health
```bash
# Check environment health
aws elasticbeanstalk describe-environment-health \
  --environment-name my-app-bluegreen-blue \
  --attribute-names All
```

### Application Versions
```bash
# List application versions
aws elasticbeanstalk describe-application-versions \
  --application-name my-app-bluegreen
```

## 🛠️ Customization

### Adding New Application Versions

1. **Create new app folder**: `app-v3/`
2. **Update packaging scripts**: Add v3 to scripts
3. **Create new Terraform resources**: Follow blue/green pattern
4. **Deploy**: Run terraform apply

### Changing Instance Types

Update `terraform.tfvars`:
```hcl
instance_type = "t3.small"  # or any other instance type
```

### Multi-Region Deployment

1. **Add provider aliases** for different regions
2. **Duplicate environment resources** with different providers
3. **Update DNS routing** for global load balancing

## 🔒 Security Best Practices

- **IAM Roles**: Least privilege access
- **S3 Bucket**: Private with public access blocked
- **Environment Variables**: Use for sensitive configuration
- **VPC**: Deploy in private subnets (optional enhancement)

## 💰 Cost Optimization

- **Instance Types**: Use t3.micro for development
- **Auto Scaling**: Configure min/max instances appropriately
- **Scheduled Scaling**: Scale down during off-hours
- **Environment Termination**: Terminate unused environments

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: This will delete all environments and the S3 bucket with application versions.

## 📚 Additional Resources

- [AWS Elastic Beanstalk Documentation](https://docs.aws.amazon.com/elasticbeanstalk/)
- [Blue/Green Deployment Best Practices](https://aws.amazon.com/builders-library/automating-safe-hands-off-deployments/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Troubleshooting

### Common Issues

**Solution Stack Not Found**
```bash
# Get available stacks
aws elasticbeanstalk list-available-solution-stacks \
  --query "SolutionStacks[?contains(@, 'Node.js 20')]"
```

**Application Version Upload Failed**
- Ensure packaging scripts ran successfully
- Check S3 bucket permissions
- Verify ZIP file exists in correct location

**Environment Creation Failed**
- Check IAM permissions
- Verify solution stack name
- Review CloudWatch logs

### Getting Help

- Check Terraform logs: `TF_LOG=DEBUG terraform apply`
- Review AWS CloudWatch logs
- Check Elastic Beanstalk event logs in AWS Console

---

**Happy Deploying! 🚀**