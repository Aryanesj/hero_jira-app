# ==============================| Variables |==================================
variable "vpc_cidr" {
  type        = string
  description = "default vpc cird block"
  default     = "10.0.0.0/16"
}

variable "env" {
  type        = string
  description = "default environment for tags in current project"
  default     = "dev"
}

variable "public_subnet_cidrs" {
  type        = list(any)
  description = "public subnet cirds"
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

variable "private_subnet_cidrs" {
  type        = list(any)
  description = "private subnet cirds"
  default = [
    "10.0.11.0/24",
    "10.0.22.0/24",
    "10.0.33.0/24"
  ]
}
