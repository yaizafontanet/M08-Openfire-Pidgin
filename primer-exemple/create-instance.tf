# create-instance.tf
 
resource "aws_key_pair" "keypair" {
    #key_name    = "TerraformAnsible-Keypair"
    key_name    = var.key_pair
    #public_key  = "joc-key-pair.pub"
    public_key  = "${file("joc-key-pair.pub")}"
}

data "template_file" "user_data" {
  template = file("./initial-setup.yaml")
}

resource "aws_instance" "instance" {
  ami                         = var.instance_ami
#  availability_zone           = "${var.aws_region}${var.aws_region_az}"
  instance_type               = var.instance_type
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = aws_subnet.subnet.id
  #key_name                    = var.key_pair
  key_name                    = aws_key_pair.keypair.key_name
  user_data                   = "${file("auto-install.sh")}"
  ### ok ### user_data                   = data.template_file.user_data.rendered 
#  root_block_device {
#    delete_on_termination = true
#    encrypted             = false
#    volume_size           = var.root_device_size
#    volume_type           = var.root_device_type
#  }
 
  tags = {
    "Owner"               = var.owner
    "Name"                = "${var.owner}-instance"
    "KeepInstanceRunning" = "false"
  }
}
