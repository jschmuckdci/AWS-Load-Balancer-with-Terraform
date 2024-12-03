# AWS Infrastructure with Terraform

This project demonstrates the deployment of a scalable, secure, and fault-tolerant web application infrastructure using Terraform on AWS. It creates an AWS VPC infrastructure spanning two Availability Zones (AZs) with public and private subnets. It deploys an internet gateway, a NAT gateway, and configures public and private route tables for secure network traffic routing. Additionally, it sets up an Application Load Balancer (ALB) that distributes traffic across an Auto Scaling Group (ASG) of Nginx web servers. Security groups are implemented to enforce strict access control between the different components.

---

## Project Architecture

### Key Components:
1. **VPC and Subnets:**
   - VPC (`10.0.0.0/16`) spanning two AZs (`us-west-2a`, `us-west-2b`).
   - Subnets per AZ:
     - **Public:** For internet-facing resources.
     - **Private:** For isolated resources.

2. **Gateways:**
   - **Internet Gateway (IGW):** Internet access for public subnets.
   - **NAT Gateways:** One per AZ for outbound internet access from private subnets. You could use 1 for both AZs based on your needs.

3. **Route Tables:**
   - Public subnets: Default route to the IGW.
   - Private subnets: Default route to respective NAT gateways.

4. **Security Groups:**
   - **`lb_sg`:** Allows inbound traffic on ports 22, 80, 443 for the load balancer.
   - **`bastion_sg`:** SSH access to the bastion host from a specific IP.
   - **`nginx_sg`:** 
     - SSH from the bastion host.
     - HTTP/HTTPS from the load balancer.

5. **Bastion Host:**
   - Deployed in a public subnet (AZ `us-west-2a`).
   - Acts as a secure entry point to private resources.

6. **Nginx Web Servers:**
   - Managed via Auto Scaling Group (ASG) using a launch template.
   - Deployed in private subnets across both AZs.

7. **Application Load Balancer (ALB):**
   - Public subnets in both AZs.
   - Distributes traffic to Nginx servers in the private subnets via a target group.

---

## Setting Up the Infrastructure

### Prerequisites:
- **Terraform Installed:** Refer to the [Terraform documentation](https://www.terraform.io/) for installation instructions.
- **AWS Credentials Configured:** Use the AWS CLI or set environment variables.
- **SSH Key Pair:** Required for bastion host access. Create or use an existing key pair in AWS.

### Deployment Steps:
1. **Clone the Repository:** Clone the project repository to your local machine.
2. **Navigate to the Directory:** Use the terminal to navigate to the directory with the Terraform code.
3. **Initialize Terraform:** 
   ```bash
   terraform init

