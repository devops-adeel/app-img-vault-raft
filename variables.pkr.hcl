# General variables
variable "project_id" {
  type        = string
  description = "The project ID to host the cluster in (required)"
  default     = "accelerator-gcp-vault"
}

variable "zone" {
  type        = string
  description = "The zone to create the packer image instance in"
  default     = "us-central1-a"
}

variable "source_image_id" {
  type        = string
  description = "The ID of the source image to start with"
  default     = "ubuntu-2004-focal-v20210623"
}

variable "ssh_username" {
  type        = string
  description = "The SSH username"
  default     = "ubuntu"
}
