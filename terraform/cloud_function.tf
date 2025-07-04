resource "google_storage_bucket" "cloudfunctions_bucket" {
  name          = join("-", ["bucket-inupa", terraform.workspace])
  provider      = google-beta
  location      = var.region
  force_destroy = true
}

data "archive_file" "weather_service_file" {
  type        = "zip"
  output_path = "${path.module}/.files/weather_service.zip"
  source {
    content  = file("${local.src_dir}/api/main.py")
    filename = "main.py"
  }
  source {
    content  = file("${local.src_dir}/api/weather.py")
    filename = "weather.py"
  }
  source {
    content  = file("${local.src_dir}/api/requirements.txt")
    filename = "requirements.txt"
  }
}

resource "google_storage_bucket_object" "weather_service_zip" {
  name       = format("%s#%s", "weather_service.zip", data.archive_file.weather_service_file.output_md5)
  bucket     = google_storage_bucket.cloudfunctions_bucket.name
  source     = "${path.module}/.files/weather_service.zip"
  provider   = google-beta
  depends_on = [data.archive_file.weather_service_file]
}

resource "google_cloudfunctions2_function" "weather_service" {
  name        = join("-", ["weather-service", terraform.workspace])
  description = "Small Cloud Function to get Weather Information"
  location    = var.region
  provider    = google-beta
  build_config {
    runtime     = "python311"
    entry_point = "handle_request"
    source {
      storage_source {
        bucket = google_storage_bucket.cloudfunctions_bucket.name
        object = google_storage_bucket_object.weather_service_zip.name
      }
    }
  }
  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
  }
  depends_on = [google_storage_bucket_object.weather_service_zip]
}