/**
* The public key for the key pair we'll use to ssh into our bastion instance.
*/
resource "aws_key_pair" "bastion" {
  key_name   = "ceros-ski-bastion-key-us-east-1a"
  public_key = var.public_key
}

/**
* This parameter contains the AMI ID for the most recent Amazon Linux 2 ami,
* managed by AWS.
*/
data "aws_ssm_parameter" "linux2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn-ami-hvm-x86_64-ebs"
}

/**
* Launch a bastion instance we can use to gain access to the private subnets of
* this availabilty zone.
*/

resource "aws_instance" "bastion" {
  ami           = data.aws_ssm_parameter.linux2_ami.value
  key_name      = aws_key_pair.bastion.key_name
  instance_type = "t3.micro"

  associate_public_ip_address = true
  subnet_id                   = element(tolist(var.public_subnets), 0)
  vpc_security_group_ids      = [var.security_group_bastion_id]

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Name        = "ceros-ski-${var.environment}-us-east-1a-bastion"
    Resource    = "modules.availability_zone.aws_instance.bastion"
  }
}