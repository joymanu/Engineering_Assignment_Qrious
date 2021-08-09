variable "my_access_key" {
    type = string 
}

variable "my_secret_key" {
    type = string 
}

variable "my_region" {
    type = string  
}
variable "allowed_ips" {
    type = list(string)
}

variable "vpc_cidr_block_var" {
    type = string
}

variable "subnet_cidr_block" {
    type = string      
}

variable "private_key_name" {
    type = string  
}

variable "key_path" {
    type = string  
}

variable "private_key" {
    type = string
}
variable "ami" {
  type = string
}