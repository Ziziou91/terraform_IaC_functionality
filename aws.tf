
provider "aws" {
	region = "eu-west-1"
    access_key = var.AWS_ACCESS_KEY_ID
    secret_key = var.AWS_SECRET_KEY
}

## ========VPC========
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
}

## ========INTERNET GATEWAY========
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "terraform-app-gw"
    }
}

## ========ROUTE TABLE========
resource "aws_route_table" "app-route-table" {
    vpc_id = aws_vpc.main.id
    
    route {
        cidr_block = var.route_table_ips.ip4_cidr_block
        gateway_id = aws_internet_gateway.gw.id
    }
    route {
        ipv6_cidr_block = var.route_table_ips.ipv6_cidr_block
        gateway_id = aws_internet_gateway.gw.id
    }

    tags = {
        Name = "terraform-app-rt"
    }
}


## ========SUBNETS========
resource "aws_subnet" "subnet" {
  for_each = var.subnets

  vpc_id     = aws_vpc.main.id
  cidr_block = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = each.key
  }
}

## ========ASSOCIATE SUBNET WITH ROUTE TABLE========
resource "aws_route_table_association" "web_rta" {
  subnet_id      = aws_subnet.subnet["web"].id
  route_table_id = aws_route_table.app-route-table.id
}


resource "aws_security_group" "sg" {
    # iterate over security_groups map to create db and app
    for_each = var.security_groups

    name        = each.value.name
    description = each.value.description
    vpc_id      = aws_vpc.main.id

    dynamic "ingress" {
        # iterate over dynamic ingress rules to create each ingress rule
        for_each = each.value.ingress
        content {
            description = ingress.value.description
            from_port   = ingress.value.from_port
            to_port     = ingress.value.to_port
            protocol    = ingress.value.protocol
            cidr_blocks = ingress.value.cidr_blocks
        }
    }
        egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = each.key
    }
}

## ========CREATE DB========
resource "aws_instance" "db" {
    ami = var.db_instance.ami
    instance_type = var.db_instance.instance_type
    availability_zone = var.db_instance.availability_zone
    key_name = var.key_name
    vpc_security_group_ids = [
        for sg in var.db_instance.security_groups : aws_security_group.sg[sg].id
    ]
    subnet_id = aws_subnet.subnet[var.db_instance.subnet].id

    associate_public_ip_address = true

    tags = {
        Name = var.db_instance.name
    }

}

## ========CREATE APP========
resource "aws_launch_configuration" "app" {
    name = "aws_launch_configuration"
    image_id = var.app_instance.ami
    instance_type = var.app_instance.instance_type
    availability_zone = var.app_instance.availability_zone
    key_name = var.key_name
    security_groups = [
        for sg in var.app_instance.security_groups : aws_security_group.sg[sg].id
    ]
    subnet_id = aws_subnet.subnet[var.app_instance.subnet].id

    associate_public_ip_address = true

    user_data = templatefile(var.app_instance.user_data, {
        db_ip = aws_instance.db.private_ip
    })

    lifecycle {
       create_before_destroy = true
    }

    tags = {
        Name = var.app_instance.name
    }

}

## ========AUTOSCALER========
resource "aws_autoscaling_group" "app" {
  launch_configuration = aws_launch_configuration.app.id
  min_size             = 2
  max_size             = 3
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.public1.id, aws_subnet.public2.id]
 
  tag {
    key                 = "Name"
    value               = "app-instance"
    propagate_at_launch = true
  }
 
  target_group_arns = [
    aws_lb_target_group.app_http.arn,
    aws_lb_target_group.app_ssh.arn
  ]
}

## ========LOAD BALANCER========
resource "aws_lb" "app" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]
 
  enable_deletion_protection = false
 
  tags = {
    Name = "app-load-balancer"
  }
}
 
resource "aws_lb_target_group" "app_http" {
  name     = "app-http-target-group"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id
 
  health_check {
    interval            = 30
    protocol            = "HTTP"
    path                = "/"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
 
  tags = {
    Name = "app-http-target-group"
  }
}
 
resource "aws_lb_target_group" "app_ssh" {
  name     = "app-ssh-target-group"
  port     = 22
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id
 
  health_check {
    interval            = 30
    protocol            = "TCP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
 
  tags = {
    Name = "app-ssh-target-group"
  }
}
 
resource "aws_lb_listener" "app_http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_http.arn
  }
 
  tags = {
    Name = "app-http-listener"
  }
}
 
resource "aws_lb_listener" "app_ssh" {
  load_balancer_arn = aws_lb.app.arn
  port              = 22
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_ssh.arn
  }
 
  tags = {
    Name = "app-ssh-listener"
  }
}
