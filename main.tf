provider "aws" {
  region = "ap-southeast-1"
}

## creating a vpc

resource "aws_vpc" "vpc_singa" {
  cidr_block = "192.168.1.0/24"
  tags = {
    Name = "vpc-mum"
  }
}

resource "aws_subnet" "pub_sub1" {
  vpc_id                  = aws_vpc.vpc_singa.id
  cidr_block              = "192.168.1.0/25"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Pub_Sub"
  }
}

resource "aws_subnet" "pub_sub2" {
  vpc_id                  = aws_vpc.vpc_singa.id
  cidr_block              = "192.168.1.128/25"
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Pub_Sub2"
  }
}
resource "aws_internet_gateway" "igw_singa" {
  vpc_id = aws_vpc.vpc_singa.id
  tags = {
    Name = "IGW_singa"
  }
}

resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.vpc_singa.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_singa.id
  }

  tags = {
    Name = "RT_Public"
  }
}



resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.pub_sub1.id
  route_table_id = aws_route_table.pub_rt.id
}


resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.pub_sub2.id
  route_table_id = aws_route_table.pub_rt.id
}
resource "aws_security_group" "sg_ec2" {
  name        = "sg_web"
  description = "Allow ssh and http traffic"
  vpc_id      = aws_vpc.vpc_singa.id

  ingress {
    description      = "allow ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "allow http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "allow http"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Env     = "test"
    project = "CI/CD"
  }
}

### creating a ec2 instances

resource "aws_instance" "pub_inst" {
  ami = "ami-08be951cec06726be"
  # availability_zone = "ap-south-1a"
  subnet_id              = aws_subnet.pub_sub1.id
  instance_type          = "t2.medium"
  vpc_security_group_ids = [aws_security_group.sg_ec2.id]
  key_name               = "k8s-m"
  tags = {
    Name = "web-server"
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("k8s-m.pem")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "./jenkins.yaml"
    destination = "/home/ubuntu/jenkins.yaml"
  }
  provisioner "file" {
    source      = "./add-sudo.sh"
    destination = "/home/ubuntu/add-sudo.sh"
  }
  provisioner "remote-exec" {   
    inline = [
      "sudo apt-add-repository ppa:ansible/ansible -y",
      "sudo apt update",
      "sudo apt install ansible -y",
      "sed -i 's/\r$//' add-sudo.sh",
      "sudo bash add-sudo.sh",
      "sudo ansible-playbook jenkins.yaml"
    ]
  }
}


output "public_ip" {
  value = aws_instance.pub_inst.public_ip
}

output "public_dns" {
  value = aws_instance.pub_inst.public_dns
}