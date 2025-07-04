variable "project" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for this project"
  default     = "europe-west4"
  type        = string
}
