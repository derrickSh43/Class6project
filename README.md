Here's a **README.md** template for your project:

---

# **AWS Bastion Host and Secure Grafana Access Setup**

This project demonstrates the deployment of a secure AWS infrastructure for accessing a private Grafana server via a bastion host. The setup includes:
- A bastion host in a public subnet for secure SSH access.
- A private Grafana server in a private subnet.
- Security group configurations for controlled access.
- Use of Terraform for infrastructure as code.

---

## **Table of Contents**
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Terraform Configuration](#terraform-configuration)
5. [Usage](#usage)
6. [Security Considerations](#security-considerations)
7. [Outputs](#outputs)

---

## **Project Overview**

The goal of this project is to securely host a Grafana server in a private subnet while allowing access through a bastion host. SSH tunneling is used to provide secure access to the Grafana dashboard without exposing it to the internet.

---

## **Architecture**

### Components:
1. **VPC**: A custom VPC with public and private subnets.
2. **Bastion Host**: An EC2 instance in the public subnet, acting as a jump server.
3. **Private Server (Grafana)**: An EC2 instance in the private subnet hosting Grafana.
4. **Security Groups**:
   - Restricts access to the bastion host and Grafana server.
5. **NAT Gateway**: Enables the private Grafana server to access the internet for updates.
6. **SSH Tunneling**: Used for secure access to the Grafana dashboard.

---

## **Prerequisites**
1. [Terraform](https://www.terraform.io/downloads.html) installed on your local machine.
2. AWS credentials configured with sufficient permissions to manage EC2, VPC, and IAM.
3. A valid SSH key pair for accessing the bastion host (`Siem.pem`).

---

## **Terraform Configuration**

### Key Files:
- `main.tf`: Defines the infrastructure resources.
- `outputs.tf`: Configures outputs for public/private IPs.
- `variables.tf`: Stores configurable parameters.

### Key Resources:
1. **Bastion Host**:
   - Publicly accessible instance for SSH access.
   - Configured with port `22` open only to a trusted IP range.

2. **Grafana Server**:
   - Private instance hosting Grafana.
   - Access controlled via security groups.

3. **NAT Gateway**:
   - Enables private subnet instances to access the internet for updates.

4. **SSH Tunneling**:
   - Port forwarding from local machine to Grafana's private IP and port.

---

## **Usage**

### Deploy the Infrastructure
1. Initialize Terraform:
   ```bash
   terraform init
   ```
2. Validate the configuration:
   ```bash
   terraform validate
   ```
3. Apply the configuration:
   ```bash
   terraform apply
   ```
4. Note the outputs, including the bastion host's public IP and Grafana's private IP.

### Access Grafana via SSH Tunnel
1. Set up an SSH tunnel to the Grafana server:
   ```bash
   ssh -L 3000:<GRAFANA_PRIVATE_IP>:3000 ec2-user@<BASTION_PUBLIC_IP>
   ```
2. Open your browser and navigate to:
   ```
   http://localhost:3000
   ```

---

## **Security Considerations**

1. **Restrict SSH Access**:
   - Limit SSH ingress to your trusted IPs (`/32`) in the security group.

2. **Use Agent Forwarding**:
   - Avoid transferring private keys to the bastion host. Use:
     ```bash
     ssh -A -i <LOCAL_KEY_FILE> ec2-user@<BASTION_PUBLIC_IP>
     ```

3. **Encrypt Grafana Traffic**:
   - Set up HTTPS for Grafana to encrypt dashboard communication.

4. **IAM Role for Instances**:
   - Use least privilege IAM roles for accessing AWS resources.

---

## **Outputs**

The following outputs are configured in the project:
- **Bastion Public IP**: Used for SSH access to the bastion host.
- **Grafana Private IP**: Used for SSH tunneling to the private Grafana server.

Run the following command to view outputs:
```bash
terraform output
```

---

## **Future Enhancements**
1. Automate HTTPS configuration for Grafana using Let's Encrypt.
2. Use AWS Systems Manager Session Manager for agentless access to private instances.
3. Add monitoring and alerts for infrastructure health.

