variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "Bot Trapper VPC"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}
