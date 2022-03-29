# create-sg.tf
 
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}
 
resource "aws_security_group" "sg" {
  name        = "${var.owner}-sg"
  description = "Allow inbound traffic via SSH"
  vpc_id      = aws_vpc.vpc.id
 
  ingress = [{
    description      = "My public IP"
    protocol         = var.sg_ingress_proto
    from_port        = var.sg_ingress_ssh
    to_port          = var.sg_ingress_ssh
    cidr_blocks      = ["${chomp(data.http.myip.body)}/32"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
 
  },
  {
    description      = "email"
    protocol         = "tcp"
    from_port        = 25
    to_port          = 25
    cidr_blocks      = [var.sg_egress_cidr_block]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
,
  {
    description      = "email"
    protocol         = "tcp"
    from_port        = 143
    to_port          = 143
    cidr_blocks      = [var.sg_egress_cidr_block]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
,
  {
    description      = "http"
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = [var.sg_egress_cidr_block]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
,
  {
    description      = "email"
    protocol         = "tcp"
    from_port        = 993
    to_port          = 993
    cidr_blocks      = [var.sg_egress_cidr_block]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
,
  {
    description      = "email"
    protocol         = "tcp"
    from_port        = 995
    to_port          = 995
    cidr_blocks      = [var.sg_egress_cidr_block]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
,
  {
    description      = "starttls smpt"
    protocol         = "tcp"
    from_port        = 587
    to_port          = 587
    cidr_blocks      = [var.sg_egress_cidr_block]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
,
  {
    description      = "pop3l"
    protocol         = "tcp"
    from_port        = 110
    to_port          = 110
    cidr_blocks      = [var.sg_egress_cidr_block]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
,
  {
    description      = "https"
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = [var.sg_egress_cidr_block]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
 ]
 
  egress = [{
    description      = "All traffic"
    protocol         = var.sg_egress_proto
    from_port        = var.sg_egress_all
    to_port          = var.sg_egress_all
    cidr_blocks      = [var.sg_egress_cidr_block]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
 
  }]
 
  tags = {
    "Owner" = var.owner
    "Name"  = "${var.owner}-sg"
  }
}
