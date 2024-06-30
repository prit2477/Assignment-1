
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a" # Change this to your preferred AZ
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.main.id

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

resource "aws_instance" "ec2" {
  ami           = "ami-0c55b159cbfafe1f0" # Change this to your preferred AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet.id
  security_groups = [aws_security_group.sg.name]
  key_name      = "MyKeyPair" 

  tags = {
    Name = "NetSPI_EC2"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y amazon-efs-utils
              mkdir -p /data/test
              mount -t efs ${aws_efs_file_system.efs.id}:/ /data/test
              EOF

  associate_public_ip_address = true
}

resource "aws_efs_file_system" "efs" {}

resource "aws_efs_mount_target" "mount_target" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = aws_subnet.subnet.id
  security_groups = [aws_security_group.sg.id]
}

resource "aws_s3_bucket" "bucket" {
  bucket = "netspi-bucket" # Change this to a unique bucket name

  tags = {
    Name    = "NetSPI_S3"
    Project = "NetSPI"
  }
}



resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.ec2.id
  allocation_id = "<EIP ALLOCATION ID>" # Replace with your Elastic IP Allocation ID
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "netspi-instance-profile"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name = "netspi-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "policy" {
  name = "netspi-policy"
  role = aws_iam_role.role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "elasticfilesystem:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
