
###############################################################################
# TERRAFORM AND AWS PROVIDER CONFIGURATION
###############################################################################

# This block defines the Terraform version requirements and AWS provider.
# The AWS provider allows Terraform to communicate with AWS services
# and manage infrastructure resources programmatically.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.67.0"
    }
  }
}

# AWS Provider Configuration
# The provider uses the region_name variable to determine the AWS region
# in which all AWS infrastructure resources will be created.

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
