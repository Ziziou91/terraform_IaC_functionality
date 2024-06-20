
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
        Name = "terraform-app"
    }
}

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
resource "aws_instance" "app" {
    ami = var.app_instance.ami
    instance_type = var.app_instance.instance_type
    availability_zone = var.app_instance.availability_zone
    key_name = var.key_name
    vpc_security_group_ids = [
        for sg in var.app_instance.security_groups : aws_security_group.sg[sg].id
    ]
    subnet_id = aws_subnet.subnet[var.app_instance.subnet].id

    associate_public_ip_address = true

    user_data = templatefile(var.app_instance.user_data, {
        db_ip = aws_instance.db.private_ip
    })

    tags = {
        Name = var.app_instance.name
    }

}