# ==============================| Variables |==================================
variable "name" {
  type        = string
  description = "Name preffix for all resources"
  default     = "dev"
}

variable "deletion_protection" {
  type        = bool
  description = "Value for deletion_protection parameter"
  default     = false
}
