// VPC
resource "aws_vpc" "security_zone" {
      cidr_block = "10.230.0.0/16" #Choose corresponding CIDR

  tags = {
    Name = "app1"
  }
  
}

// Subnet
resource "aws_subnet" "private-security-zone" { #Change to your AZ
  vpc_id            = aws_vpc.security_zone.id
  cidr_block        = "10.230.0.0/24"
  availability_zone = "us-east-1a" #Change to your AZ

  tags = {
    Name    = "private-security-zone" #Change to your AZ
    Service = "logs-collection"
    Owner   = "Chewbacca"
    Planet  = "Musafar"
  }
}
resource "aws_subnet" "public-security-zone" { #Change to your AZ
  vpc_id            = aws_vpc.security_zone.id
  cidr_block        = "10.230.1.0/24"
  availability_zone = "us-east-1a" #Change to your AZ
  map_public_ip_on_launch = true

  tags = {
    Name    = "public-security-zone" #Change to your AZ
    Service = "logs-collection"
    Owner   = "Chewbacca"
    Planet  = "Musafar"
  }
}
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}
// NAT
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-security-zone.id

  tags = {
    Name = "nat-gateway"
  }
}

// Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.security_zone.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private_rta" {
  subnet_id      = aws_subnet.private-security-zone.id
  route_table_id = aws_route_table.private.id
}

resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.security_zone.id

  tags = {
    Name = "example-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.security_zone.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public-security-zone.id
  route_table_id = aws_route_table.public.id
}

// IAM Role
resource "aws_iam_role" "siem_instance_role" {
  name = "siem-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}
resource "aws_iam_role_policy" "siem_policy" {
  role = aws_iam_role.siem_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ssm:DescribeParameters",
          "ec2messages:GetMessages",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:SendReply"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

// Instance
resource "aws_instance" "SIEM_Server" {
  ami                         = "ami-0453ec754f44f9a4a"
  instance_type               = "t3.medium"
  key_name                    = "Siem"
  subnet_id                   = aws_subnet.private-security-zone.id
  vpc_security_group_ids      = [aws_security_group.SIEM_SG.id]
  iam_instance_profile        = aws_iam_instance_profile.siem_profile.id

    root_block_device {
    volume_size = 20  # Specify the size in GB
    volume_type = "gp3"  # General Purpose SSD
  }

  user_data = filebase64("userdata.sh")
  tags = {
    Name = "SIEM_Server"
  }
}
resource "aws_iam_instance_profile" "siem_profile" {
  name = "siem-instance-profile"
  role = aws_iam_role.siem_instance_role.name
}
 

resource "aws_security_group" "SIEM_SG" {
    vpc_id = aws_vpc.security_zone.id

    ingress {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["${aws_instance.Bastion_Host.private_ip}/32"]
     
    }

    ingress {
        from_port   = 3100
        to_port     = 3100
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    
}

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["${aws_instance.Bastion_Host.private_ip}/32"]
    
}

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

// Bastion Host
resource "aws_instance" "Bastion_Host" {
  ami                         = "ami-0453ec754f44f9a4a"
  instance_type               = "t2.micro"
  key_name                    = "Siem"
  subnet_id                   = aws_subnet.public-security-zone.id
  vpc_security_group_ids      = [aws_security_group.Bastion_instance.id]


    root_block_device {
    volume_size = 8  # Specify the size in GB
    volume_type = "gp2"  # General Purpose SSD
  }
    tags = {
    Name = "Bastion_Host"
  }
}

resource "aws_security_group" "Bastion_instance" {
  name        = "Bastion_instance"
  description = "Bastion instance security group"
  vpc_id     = aws_vpc.security_zone.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// outputs
output "grafana_private_ip" {
  description = "The private IP of the Grafana server"
  value       = aws_instance.SIEM_Server.private_ip
}

output "bastion_public_ip" {
  description = "The public IP of the bastion host"
  value       = aws_instance.Bastion_Host.public_ip
}




/*
Read Me 
------------------------------UPDATE WITH THE CORRECT IP ADDRESSES --------------------------------
Bastion commands
eval "$(ssh-agent -s)"
ssh-add Siem.pem 
ssh -A -i Siem.pem ec2-user@54.85.15.178
ssh ec2-user@10.230.0.205

From a new Terminal 
ssh -i Siem.pem -L 3000:10.230.0.205:3000 ec2-user@54.85.15.178
Leave that new Terminal window open and
goto http://localhost:3000 in your browser

*/
