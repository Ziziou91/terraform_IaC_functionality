# ====================================
# ----------GITHUB VARIABLES----------
# ====================================
variable "GITHUB_TERRAFORM_TOKEN" {
    type = string
}

variable "files_to_commit" {
    type = list(string)
}

# ====================================
# -----------AWS VARIABLES------------
# ====================================
variable "AWS_ACCESS_KEY_ID" {
    type = string
}

variable "AWS_SECRET_KEY" {
    type = string
}

variable "key_name" {
    type = string
}

## -----------VPC------------
variable vpc_cidr_block {
    type = string
}

## -----------ROUTE TABLE------------
variable route_table_ips {
    type = object({
      ip4_cidr_block = string
      ipv6_cidr_block = string 
    })
}

## -----------SUBNETS------------
variable "subnets" {
    type = map(object({
        cidr_block = string
        availability_zone = string
    }))
}

## -----------SECURITY GROUPS------------
variable "security_groups" {
    type = map(object({
        name        = string
        description = string
        ingress = list(object({
            description = string
            from_port   = number
            to_port     = number
            protocol    = string
            cidr_blocks = list(string)
        }))
    }))
}

## -----------EC2 SETTINGS------------
variable "db_instance" {
    type = object({
        name = string
        ami = string
        availability_zone = string
        instance_type   = string
        security_groups = list(string)
        subnet = string
    })
}

variable "app_instance" {
    type = object({
        name = string
        ami = string
        availability_zone = string
        instance_type   = string
        security_groups = list(string)
        subnet = string
        user_data = string
    })   
}