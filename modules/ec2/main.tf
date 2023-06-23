data "aws_ami" "rhel-9" {
  most_recent = true
  owners      = ["309956199498"]  # AWS Marketplace RHEL owner ID

   filter {
    name   = "name"
    values = ["RHEL-9*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}



resource "aws_instance" "ec2_public" {
  count                       = 3
  ami                         = data.aws_ami.rhel-9.id
  associate_public_ip_address = true
  instance_type               = "t3.2xlarge"
  key_name                    = var.key_name
  subnet_id                   = var.vpc.public_subnets[0]
  vpc_security_group_ids      = [var.sg_pub_id]

  tags = {
    "Name" = "${var.namespace}-EC2-PUBLIC-${count.index + 1}"
  }

  # Copies the ssh key file to home dir
  provisioner "file" {
    source      = "./${var.key_name}.pem"
    destination = "/home/ec2-user/${var.key_name}.pem"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${var.key_name}.pem")
      host        = self.public_ip
    }
  }
  
  //chmod key 400 on EC2 instance
  provisioner "remote-exec" {
    inline = ["chmod 400 ~/${var.key_name}.pem"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${var.key_name}.pem")
      host        = self.public_ip
    }
  }
}

// Configure the EC2 instance in a private subnet
resource "aws_instance" "ec2_private" {
  ami                         = data.aws_ami.rhel-9.id
  count                       = 3
  associate_public_ip_address = false
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  subnet_id                   = var.vpc.private_subnets[1]
  vpc_security_group_ids      = [var.sg_priv_id]

  tags = {
    "Name" = "${var.namespace}-EC2-PRIVATE"
  }

}