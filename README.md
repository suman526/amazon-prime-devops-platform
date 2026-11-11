<<<<<<< HEAD
# Amazon Prime Clone Deployment Project
![Pipeline Overview](<img width="554" height="309" alt="Animated DevOps Pipeline Flow final" src="https://github.com/user-attachments/assets/7fc35eb5-ad36-4845-a229-c7154819346a" />
)

## Project Overview
This project demonstrates deploying an Amazon Prime clone using a set of DevOps tools and practices. The primary tools include:

- **Terraform**: Infrastructure as Code (IaC) tool to create AWS infrastructure such as EC2 instances and EKS clusters.
- **GitHub**: Source code management.
- **Jenkins**: CI/CD automation tool.
- **SonarQube**: Code quality analysis and quality gate tool.
- **NPM**: Build tool for NodeJS.
- **Aqua Trivy**: Security vulnerability scanner.
- **Docker**: Containerization tool to create images.
- **AWS ECR**: Repository to store Docker images.
- **AWS EKS**: Container management platform.
- **ArgoCD**: Continuous deployment tool.
- **Prometheus & Grafana**: Monitoring and alerting tools.

## Pre-requisites
1. **AWS Account**: Ensure you have an AWS account. [Create an AWS Account](https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-creating.html)
2. **AWS CLI**: Install AWS CLI on your local machine. [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
3. **VS Code (Optional)**: Download and install VS Code as a code editor. [VS Code Download](https://code.visualstudio.com/download)
4. **Install Terraform in Windows**: Download and install Terraform in Windows [Terraform in Windows](https://learn.microsoft.com/en-us/azure/developer/terraform/get-started-windows-bash)

## Configuration
### AWS Setup
1. **IAM User**: Create an IAM user and generate the access and secret keys to configure your machine with AWS.
2. **Key Pair**: Create a key pair named `key` for accessing your EC2 instances.

## Infrastructure Setup Using Terraform
1. **Clone the Repository** (Open Command Prompt & run below):
   ```bash
   git clone https://github.com/suman526/amazon-prime-devops-platform.git
   cd DevopsProject2
   code .   # this command will open VS code in backend
   ```
2. **Initialize and Apply Terraform**:
   - Run the below commands to reduce the path displayed in VS Code terminal (Optional)
     ```bash
     code $PROFILE
     function prompt {"$PWD > "}
     function prompt {$(Get-Location -Leaf) + " > "}
     ```
   - Open `terraform_code/ec2_server/main.tf` in VS Code.
   - Run the following commands:
     ```bash
     aws configure
     terraform init
     terraform apply --auto-approve
     ```

This will create the EC2 instance, security groups, and install necessary tools like Jenkins, Docker, SonarQube, etc.

## SonarQube Configuration
1. **Login Credentials**: Use `admin` for both username and password.
2. **Generate SonarQube Token**:
   - Create a token under `Administration → Security → Users → Tokens`.
   - Save the token for integration with Jenkins.

## Jenkins Configuration
1. **Add Jenkins Credentials**:
   - Add the SonarQube token, AWS access key, and secret key in `Manage Jenkins → Credentials → System → Global credentials`.
2. **Install Required Plugins**:
   - Install plugins such as SonarQube Scanner, NodeJS, Docker, and Prometheus metrics under `Manage Jenkins → Plugins`.

3. **Global Tool Configuration**:
   - Set up tools like JDK 17, SonarQube Scanner, NodeJS, and Docker under `Manage Jenkins → Global Tool Configuration`.

## Pipeline Overview
### Pipeline Stages
1. **Git Checkout**: Clones the source code from GitHub.
2. **SonarQube Analysis**: Performs static code analysis.
3. **Quality Gate**: Ensures code quality standards.
4. **Install NPM Dependencies**: Installs NodeJS packages.
5. **Trivy Security Scan**: Scans the project for vulnerabilities.
6. **Docker Build**: Builds a Docker image for the project.
7. **Push to AWS ECR**: Tags and pushes the Docker image to ECR.
8. **Image Cleanup**: Deletes images from the Jenkins server to save space.

### Running Jenkins Pipeline
Create and run the build pipeline in Jenkins. The pipeline will build, analyze, and push the project Docker image to ECR.
Create a Jenkins pipeline by adding the following script:

### Build Pipeline

```groovy
###############################################################################
# TERRAFORM AND AWS PROVIDER CONFIGURATION
###############################################################################

# This block defines the Terraform version requirements and AWS provider.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.67.0"
    }
  }
}

# AWS Provider Configuration

provider "aws" {
  region = var.region_name
}

###############################################################################
# STEP 1: CREATE A SECURITY GROUP FOR THE JENKINS SERVER
###############################################################################

# An AWS Security Group acts as a virtual firewall for EC2 instances.
# It controls incoming (ingress) and outgoing (egress) network traffic.
#
# This security group allows access to the ports required by the
# DevOps tools and Kubernetes components used in this project.

resource "aws_security_group" "my-sg" {

  # Name of the security group displayed in the AWS console.
  name = "JENKINS-SERVER-SG"

  # Description explaining the purpose of this security group.
  description = "Jenkins Server Ports"

  # SSH ACCESS - PORT 22
  # Allows SSH connections to the EC2 instance.
  # SSH is used for remotely accessing and managing the Ubuntu server.

  ingress {
    description = "SSH Port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP ACCESS - PORT 80
  # Allows incoming HTTP traffic.
  # Used when accessing web applications over HTTP.

  ingress {
    description = "HTTP Port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS ACCESS - PORT 443
  # Allows secure HTTPS traffic.
  # Used for applications and services communicating over HTTPS.

  ingress {
    description = "HTTPS Port"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ETCD CLUSTER - PORTS 2379-2380
  # These ports are used by etcd for client communication
  # and peer-to-peer communication in Kubernetes control planes.

  ingress {
    description = "etc-cluster Port"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # GRAFANA - PORT 3000
  # Allows access to the Grafana dashboard.
  # Grafana is used to visualize application and infrastructure metrics.

  ingress {
    description = "Grafana Port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # KUBERNETES API SERVER - PORT 6443
  # Allows communication with the Kubernetes API server.
  # Kubectl uses this API endpoint to interact with a Kubernetes cluster.

  ingress {
    description = "Kube API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # JENKINS - PORT 8080
  # Jenkins uses port 8080 by default.
  # This port allows access to the Jenkins web interface.

  ingress {
    description = "Jenkins Port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SONARQUBE - PORT 9000
  # Allows access to the SonarQube dashboard.
  # SonarQube is used for static code analysis and code quality checks.

  ingress {
    description = "SonarQube Port"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PROMETHEUS - PORT 9090
  # Allows access to the Prometheus web interface.
  # Prometheus collects and stores time-series monitoring metrics.

  ingress {
    description = "Prometheus Port"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NODE EXPORTER / METRICS - PORT 9100
  # Allows access to Prometheus Node Exporter metrics.
  # Node Exporter exposes hardware and operating system metrics
  # such as CPU, memory, disk, and network utilization.

  ingress {
    description = "Prometheus Metrics Port"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # KUBERNETES KUBELET - PORTS 10250-10260
  # These ports cover Kubernetes node-level communication.
  # Port 10250 is commonly used by the Kubelet API.

  ingress {
    description = "K8s Ports"
    from_port   = 10250
    to_port     = 10260
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # KUBERNETES NODEPORT SERVICES - PORTS 30000-32767
  # Kubernetes uses this range by default for NodePort services.
  # It allows applications running inside the cluster to be exposed
  # through ports on Kubernetes nodes.

  ingress {
    description = "K8s NodePort"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # OUTBOUND TRAFFIC
  # Allows the EC2 instance to initiate outgoing connections
  # to any destination using any protocol.
  #
  # This is required for downloading packages, Docker images,
  # software dependencies, and communicating with external services.

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###############################################################################
# STEP 2: CREATE AN EC2 INSTANCE AND CONFIGURE IT USING REMOTE-EXEC
###############################################################################

# This resource provisions an EC2 virtual machine on AWS.
# The instance acts as the Jenkins server and DevOps tool management server.
#
# Terraform also uses the remote-exec provisioner to connect to the
# newly created EC2 instance through SSH and automatically install
# the required DevOps tools.

resource "aws_instance" "my-ec2" {

  # AMI ID determines which operating system image will be used.
  # The AMI ID is supplied through the ami_id variable.

  ami = var.ami_id

  # Defines the EC2 instance size and computing capacity.
  # The instance type is supplied through the instance_type variable.

  instance_type = var.instance_type

  # Associates an existing AWS EC2 key pair with the instance.
  # This key pair is used for SSH authentication.

  key_name = var.key_name

  # Attaches the previously created security group to the EC2 instance.
  # This enables the network access rules configured above.

  vpc_security_group_ids = [aws_security_group.my-sg.id]

  # CONFIGURE ROOT EBS VOLUME
  # Defines the storage capacity of the root volume.
  # The volume size is controlled through the volume_size variable.

  root_block_device {
    volume_size = var.volume_size
  }

  # EC2 INSTANCE TAGS
  # Adds a Name tag to identify the instance easily in the AWS console.

  tags = {
    Name = var.server_name
  }

  #############################################################################
  # REMOTE-EXEC PROVISIONER
  #############################################################################

  # The remote-exec provisioner executes commands directly on the
  # newly created EC2 instance.
  #
  # Terraform connects to the server using SSH and executes the
  # commands defined in the inline list below.

  provisioner "remote-exec" {

    # SSH CONNECTION CONFIGURATION
    connection {
      type = "ssh"

      # Private key used to authenticate with the EC2 instance.
      # The key.pem file must be present in the Terraform working directory.

      private_key = file("./key.pem")

      # Ubuntu is the default SSH username for Ubuntu EC2 AMIs.

      user = "ubuntu"

      # Uses the public IP of the newly created EC2 instance.

      host = self.public_ip
    }

    #############################################################################
    # INSTALL AWS CLI
    #############################################################################

    # Installs unzip, which is required to extract the AWS CLI package.

    inline = [

      "sudo apt install unzip -y",

      # Downloads the AWS CLI v2 installation package.

      "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'",

      # Extracts the downloaded AWS CLI package.

      "unzip awscliv2.zip",

      # Installs AWS CLI v2 on the EC2 instance.

      "sudo ./aws/install",

      #############################################################################
      # INSTALL DOCKER
      #############################################################################

      # Updates the Ubuntu package repository information.

      "sudo apt-get update -y",

      # Installs the required certificates and curl utility
      # for downloading Docker's official repository configuration.

      "sudo apt-get install -y ca-certificates curl",

      # Creates the directory used to store APT repository signing keys.

      "sudo install -m 0755 -d /etc/apt/keyrings",

      # Downloads Docker's official GPG signing key.
      # This key helps verify the authenticity of Docker packages.

      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc",

      # Grants read permissions to the Docker repository signing key.

      "sudo chmod a+r /etc/apt/keyrings/docker.asc",

      # Adds Docker's official APT repository to the Ubuntu system.
      # The architecture and Ubuntu release codename are detected automatically.

      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",

      # Refreshes the package index after adding the Docker repository.

      "sudo apt-get update -y",

      # Installs Docker Engine, Docker CLI, containerd,
      # Docker Buildx, and Docker Compose plugins.

      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",

      # Adds the Ubuntu user to the Docker group.
      # This allows the user to execute Docker commands without sudo
      # after starting a new login session.

      "sudo usermod -aG docker ubuntu",

      # Changes Docker socket permissions to allow all local users
      # to access the Docker daemon.
      # This is used here for convenience, but is not recommended
      # for production environments.

      "sudo chmod 777 /var/run/docker.sock",

      # Verifies that Docker has been installed successfully.

      "docker --version",

      #############################################################################
      # INSTALL SONARQUBE USING DOCKER
      #############################################################################

      # Downloads the SonarQube LTS Community image from Docker Hub
      # and starts a container in detached mode.
      #
      # Container name: sonar
      # Host port: 9000
      # Container port: 9000

      "docker run -d --name sonar -p 9000:9000 sonarqube:lts-community",

      #############################################################################
      # INSTALL AQUA TRIVY
      #############################################################################

      # Installs utilities required to download and configure
      # the official Trivy APT repository.

      "sudo apt-get install -y wget apt-transport-https gnupg",

      # Downloads Trivy's official repository public key
      # and converts it into a GPG keyring format.

      "wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null",

      # Adds the official Aqua Security Trivy repository
      # to the Ubuntu APT sources list.

      "echo 'deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main' | sudo tee -a /etc/apt/sources.list.d/trivy.list",

      # Refreshes the package repository information.

      "sudo apt-get update -y",

      # Installs Trivy.
      # Trivy is used to scan container images, dependencies,
      # filesystems, and other artifacts for security vulnerabilities.

      "sudo apt-get install trivy -y",

      #############################################################################
      # INSTALL KUBECTL
      #############################################################################

      # Downloads the Kubernetes command-line tool.
      # This configuration downloads the kubectl binary for version 1.30.4.

      "curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.4/2024-09-11/bin/linux/amd64/kubectl",

      # Downloads the SHA-256 checksum file for the kubectl binary.

      "curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.4/2024-09-11/bin/linux/amd64/kubectl.sha256",

      # Verifies the downloaded kubectl binary against its checksum.

      "sha256sum -c kubectl.sha256",

      # Calculates the SHA-256 checksum of the downloaded binary.
      # This command displays the checksum for manual verification.

      "openssl sha1 -sha256 kubectl",

      # Grants executable permission to the kubectl binary.

      "chmod +x ./kubectl",

      # Creates a local bin directory and copies kubectl into it.
      # Also temporarily updates PATH for the current shell.

      "mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH",

      # Adds the kubectl binary directory to PATH permanently
      # for future Bash sessions.

      "echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc",

      # Moves kubectl into the system-wide executable directory.

      "sudo mv $HOME/bin/kubectl /usr/local/bin/kubectl",

      # Grants executable permission to kubectl.

      "sudo chmod +x /usr/local/bin/kubectl",

      # Verifies the kubectl client installation.

      "kubectl version --client",

      #############################################################################
      # INSTALL HELM
      #############################################################################

      # Downloads Helm version 3.16.1.
      # Helm is a Kubernetes package manager used to install
      # and manage Kubernetes applications through Helm charts.

      "wget https://get.helm.sh/helm-v3.16.1-linux-amd64.tar.gz",

      # Extracts the downloaded Helm archive.

      "tar -zxvf helm-v3.16.1-linux-amd64.tar.gz",

      # Moves the Helm executable into the system-wide binary directory.

      "sudo mv linux-amd64/helm /usr/local/bin/helm",

      # Verifies Helm installation.

      "helm version",

      #############################################################################
      # INSTALL ARGO CD CLI
      #############################################################################

      # Retrieves the latest stable Argo CD version from GitHub.

      "VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)",

      # Downloads the Argo CD CLI binary corresponding to that version.

      "curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v$VERSION/argocd-linux-amd64",

      # Installs the Argo CD CLI in the system-wide executable directory
      # and assigns the required executable permissions.

      "sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd",

      # Removes the downloaded installation file after installation.

      "rm argocd-linux-amd64",

      #############################################################################
      # INSTALL JAVA 21
      #############################################################################

      # Refreshes the Ubuntu package repository information.

      "sudo apt-get update -y",

      # Installs Fontconfig and OpenJDK 21 JRE.
      # Java is required to run Jenkins and its Java-based components.

      "sudo apt-get install -y fontconfig openjdk-21-jre",

      # Displays the installed Java version to verify installation.

      "java -version",

      #############################################################################
      # CONFIGURE JENKINS LTS REPOSITORY
      #############################################################################

      # Creates the APT keyring directory if it does not already exist.

      "sudo mkdir -p /etc/apt/keyrings",

      # Downloads the official Jenkins 2026 repository signing key.
      # The signing key allows APT to verify the authenticity
      # of packages downloaded from the Jenkins repository.

      "sudo curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key -o /etc/apt/keyrings/jenkins-keyring.asc",

      #############################################################################
      # ADD JENKINS LTS APT REPOSITORY
      #############################################################################

      # Adds the official Jenkins Long-Term Support repository
      # to the Ubuntu package manager configuration.

      "echo 'deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/' | sudo tee /etc/apt/sources.list.d/jenkins.list",

      #############################################################################
      # INSTALL JENKINS
      #############################################################################

      # Updates package information to include the Jenkins repository.

      "sudo apt-get update -y",

      # Installs Jenkins from the official LTS repository.

      "sudo apt-get install -y jenkins",

      #############################################################################
      # START AND ENABLE JENKINS SERVICE
      #############################################################################

      # Configures Jenkins to start automatically whenever
      # the EC2 instance boots.

      "sudo systemctl enable jenkins",

      # Starts the Jenkins service immediately.

      "sudo systemctl start jenkins",

      #############################################################################
      # VERIFY JENKINS AND RETRIEVE INITIAL ADMIN PASSWORD
      #############################################################################

      # Checks whether the Jenkins service is running.
      # The command succeeds only if Jenkins is active.

      "sudo systemctl is-active --quiet jenkins",

      # Retrieves the public IP address of the EC2 instance
      # using the AWS public IP checking service.

      "ip=$(curl -s https://checkip.amazonaws.com)",

      # Reads the initial administrator password generated by Jenkins.
      # This password is required during the first Jenkins login.

      "pass=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)",

      #############################################################################
      # DISPLAY APPLICATION ACCESS DETAILS
      #############################################################################

      # Displays the Jenkins web interface URL.

      "echo \"Access Jenkins Server here --> http://$ip:8080\"",

      # Displays the Jenkins initial administrator password.

      "echo \"Jenkins Initial Password: $pass\"",

      # Displays the SonarQube web interface URL.

      "echo \"Access SonarQube Server here --> http://$ip:9000\"",

      # Displays the default SonarQube login credentials.
      # Username: admin
      # Password: admin (initial default password; change it on first login).

      "echo \"SonarQube Username & Password: admin\""

    ]
  }
}

###############################################################################
# STEP 3: OUTPUT EC2 SSH ACCESS DETAILS
###############################################################################

# This output displays the SSH username and public IP address
# of the newly provisioned EC2 instance.
#
# It can be used to connect to the Ubuntu server through SSH.

output "SERVER-SSH-ACCESS" {
  value = "ubuntu@${aws_instance.my-ec2.public_ip}"
}

###############################################################################
# STEP 4: OUTPUT EC2 PUBLIC IP ADDRESS
###############################################################################

# Displays the public IP address assigned to the EC2 instance.
# This IP can be used to access the Jenkins and SonarQube dashboards
# through a web browser, provided the services are running
# and the security group allows the required traffic.

output "PUBLIC-IP" {
  value = aws_instance.my-ec2.public_ip
}

###############################################################################
# STEP 5: OUTPUT EC2 PRIVATE IP ADDRESS
###############################################################################

# Displays the private IP address assigned to the EC2 instance.
# The private IP is used for internal communication within
# the associated VPC and connected private networks.

output "PRIVATE-IP" {
  value = aws_instance.my-ec2.private_ip
}
```

## Continuous Deployment with ArgoCD
1. **Create EKS Cluster**: Use Terraform to create an EKS cluster and related resources.
2. **Deploy Amazon Prime Clone**: Use ArgoCD to deploy the application using Kubernetes YAML files.
3. **Monitoring Setup**: Install Prometheus and Grafana using Helm charts for monitoring the Kubernetes cluster.

### Deployment Pipeline
```groovy

pipeline {
    agent any

    environment {
        KUBECTL = '/usr/local/bin/kubectl'
    }

    parameters {
        string(
            name: 'CLUSTER_NAME',
            defaultValue: 'amazon-prime-cluster',
            description: 'Enter your EKS cluster name'
        )
    }

    stages {

        // Stage 1: Login to EKS
        stage("Login to EKS") {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'access-key', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                    ]) {
                        sh """
                            aws eks --region us-east-1 update-kubeconfig --name ${params.CLUSTER_NAME}
                            kubectl get nodes
                        """
                    }
                }
            }
        }

        // Stage 2: Configure Prometheus & Grafana
        stage("Configure Prometheus & Grafana") {
            steps {
                script {
                    sh """
                        # Add Prometheus Helm repository
                        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true

                        # Update Helm repositories
                        helm repo update

                        # Create Prometheus namespace if it does not exist
                        kubectl create namespace prometheus --dry-run=client -o yaml | kubectl apply -f -

                        # Install or upgrade Prometheus and Grafana
                        helm upgrade --install stable prometheus-community/kube-prometheus-stack \
                            -n prometheus \
                            --wait \
                            --timeout 10m

                        # Expose Prometheus using LoadBalancer
                        kubectl patch svc stable-kube-prometheus-sta-prometheus \
                            -n prometheus \
                            -p '{"spec": {"type": "LoadBalancer"}}'

                        # Expose Grafana using LoadBalancer
                        kubectl patch svc stable-grafana \
                            -n prometheus \
                            -p '{"spec": {"type": "LoadBalancer"}}'

                        # Verify Prometheus and Grafana
                        kubectl get pods -n prometheus
                        kubectl get svc -n prometheus
                    """
                }
            }
        }

        // Stage 3: Configure ArgoCD
        stage("Configure ArgoCD") {
            steps {
                script {
                    sh """
                        # Step 1: Create ArgoCD namespace if it does not exist
                        kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

                        # Step 2: Install ArgoCD using Server-Side Apply
                        # Force resolution of existing field ownership conflicts
                        kubectl apply \
                            --server-side \
                            --force-conflicts \
                            -n argocd \
                            -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

                        # Step 3: Expose ArgoCD server using LoadBalancer
                        kubectl patch svc argocd-server \
                            -n argocd \
                            -p '{"spec": {"type": "LoadBalancer"}}'

                        # Step 4: Verify ArgoCD pods
                        kubectl get pods -n argocd

                        # Step 5: Verify ArgoCD services
                        kubectl get svc -n argocd
                    """
                }
            }
        }
    }

    post {
        success {
            echo 'DevOps deployment pipeline completed successfully!'
        }

        failure {
            echo 'DevOps deployment pipeline failed. Check the stage logs.'
        }

        always {
            echo 'Jenkins pipeline execution finished.'
        }
    }
}

```

## Cleanup
- Run cleanup pipelines to delete the resources such as load balancers, services, and deployment files.
- Use `terraform destroy` to remove the EKS cluster and other infrastructure.

### Cleanup Pipeline
```groovy
pipeline {
    agent any

    environment {
        KUBECTL = '/usr/local/bin/kubectl'
    }

    parameters {
        string(name: 'CLUSTER_NAME', defaultValue: 'amazon-prime-cluster', description: 'Enter your EKS cluster name')
    }

    stages {

        stage("Login to EKS") {
            steps {
                script {
                    withCredentials([string(credentialsId: 'access-key', variable: 'AWS_ACCESS_KEY'),
                                     string(credentialsId: 'secret-key', variable: 'AWS_SECRET_KEY')]) {
                        sh "aws eks --region us-east-1 update-kubeconfig --name ${params.CLUSTER_NAME}"
                    }
                }
            }
        }
        
        stage('Cleanup K8s Resources') {
            steps {
                script {
                    // Step 1: Delete services and deployments
                    sh 'kubectl delete svc kubernetes || true'
                    sh 'kubectl delete deploy pandacloud-app || true'
                    sh 'kubectl delete svc pandacloud-app || true'

                    // Step 2: Delete ArgoCD installation and namespace
                    sh 'kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml || true'
                    sh 'kubectl delete namespace argocd || true'

                    // Step 3: List and uninstall Helm releases in prometheus namespace
                    sh 'helm list -n prometheus || true'
                    sh 'helm uninstall kube-stack -n prometheus || true'
                    
                    // Step 4: Delete prometheus namespace
                    sh 'kubectl delete namespace prometheus || true'

                    // Step 5: Remove Helm repositories
                    sh 'helm repo remove stable || true'
                    sh 'helm repo remove prometheus-community || true'
                }
            }
        }
		
        stage('Delete ECR Repository and KMS Keys') {
            steps {
                script {
                    // Step 1: Delete ECR Repository
                    sh '''
                    aws ecr delete-repository --repository-name amazon-prime --region us-east-1 --force
                    '''

                    // Step 2: Delete KMS Keys
                    sh '''
                    for key in $(aws kms list-keys --region us-east-1 --query "Keys[*].KeyId" --output text); do
                        aws kms disable-key --key-id $key --region us-east-1
                        aws kms schedule-key-deletion --key-id $key --pending-window-in-days 7 --region us-east-1
                    done
                    '''
                }
            }
        }		
		
    }
}
```

## Additional Information
For further details, refer to the blog : 

---
=======
