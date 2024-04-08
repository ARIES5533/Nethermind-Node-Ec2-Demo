
###Data is used here to import existing resources

# Import existing subnet IDs using data sources
data "aws_subnet" "subnet1" {
  id = var.subnet-1
}

#Import existing subnet IDs using data sources
data "aws_vpc" "default-project-vpc" {

  tags = {
    Name = var.vpc_name
  }
}

#Import existing security group using data sources
data "aws_security_group" "aries_sg" {
  id = var.security_group
}

### Create the EC2 instance

resource "aws_instance" "Nethermind-node" {
  ami                         = var.ami # Specify your ubuntu AMI ID
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnet.subnet1.id
  iam_instance_profile        = var.instance_profile
  key_name                    = var.key
  vpc_security_group_ids      = [data.aws_security_group.aries_sg.id]
  associate_public_ip_address = true

  # User data script for initializing the EC2 instance
  user_data = <<-EOF
    #!/bin/bash

    # Redirect stdout and stderr to a log file
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

    echo "Starting user data script"

    # Update the system
    sudo apt-get update -y
    sudo apt-get upgrade -y

    # Install Docker
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker

    # Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Pull Docker image
    sudo docker pull nethermind/nethermind:latest

    # Run Docker container
    sudo docker run -d --name nethermind -p 8545:8545 \
      -e NETHERMIND_JSONRPCCONFIG_ENABLED="true" \
      -e NETHERMIND_JSONRPCCONFIG_HOST="0.0.0.0" \
      -e NETHERMIND_JSONRPCCONFIG_ENABLEDMODULES="[Eth, Mev, Web3]" \
      nethermind/nethermind:latest --JsonRpc.Enabled=true --JsonRpc.EnabledModules=[admin]

    echo "User data script executed successfully"
  EOF

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "Nethermind-node-demo"
  }
}
