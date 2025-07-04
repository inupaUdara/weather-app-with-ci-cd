provider "google" {
  project = var.project
  region  = var.region
}

provider "google-beta" {
  project = var.project
  region  = var.region
}

terraform {
  required_version = "1.12.2"
  backend "gcs" {
    bucket = "bucket-inupa"
    prefix = "terraform/edge"
  }
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.19.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# Getting the project number for assigning permissions
data "google_project" "project" {
  provider   = google-beta
  depends_on = [google_project_service.enable_api["cloudresourcemanager.googleapis.com"]]
}

# Get client config
data "google_client_config" "default" {
  provider = google-beta
}


resource "google_project_service" "enable_api" {
  project = var.project  # Add this line
  for_each = toset([
    "serviceusage.googleapis.com",
    "logging.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "iamcredentials.googleapis.com",
  ])

  service = each.key

  timeouts {
    create = "30m"
    update = "40m"
  }

  disable_on_destroy = false
}
