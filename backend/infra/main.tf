terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "firestore" {
  service            = "firestore.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudfunctions" {
  service            = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudscheduler" {
  service            = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "aiplatform" {
  service            = "aiplatform.googleapis.com"
  disable_on_destroy = false
}

# Firestore Database
resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.firestore_location
  type        = "FIRESTORE_NATIVE"

  depends_on = [google_project_service.firestore]
}

# Service Account for Cloud Functions
resource "google_service_account" "functions_sa" {
  account_id   = "goiryoku-functions"
  display_name = "Goiryoku Cloud Functions Service Account"
}

# IAM: Vertex AI User role
resource "google_project_iam_member" "functions_aiplatform" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.functions_sa.email}"
}

# IAM: Firestore User role
resource "google_project_iam_member" "functions_datastore" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.functions_sa.email}"
}

# Storage bucket for function source code
resource "google_storage_bucket" "functions_bucket" {
  name     = "${var.project_id}-goiryoku-functions"
  location = var.region

  uniform_bucket_level_access = true
}

# Archive for get_words function
data "archive_file" "get_words_source" {
  type        = "zip"
  output_path = "${path.module}/tmp/get_words.zip"

  source {
    content  = file("${path.module}/../functions/get_words/main.py")
    filename = "main.py"
  }
  source {
    content  = file("${path.module}/../functions/get_words/requirements.txt")
    filename = "requirements.txt"
  }
  source {
    content  = file("${path.module}/../functions/shared/firestore_client.py")
    filename = "firestore_client.py"
  }
  source {
    content  = file("${path.module}/../functions/shared/__init__.py")
    filename = "__init__.py"
  }
}

# Archive for generate_words function
data "archive_file" "generate_words_source" {
  type        = "zip"
  output_path = "${path.module}/tmp/generate_words.zip"

  source {
    content  = file("${path.module}/../functions/generate_words/main.py")
    filename = "main.py"
  }
  source {
    content  = file("${path.module}/../functions/generate_words/requirements.txt")
    filename = "requirements.txt"
  }
  source {
    content  = file("${path.module}/../functions/shared/firestore_client.py")
    filename = "firestore_client.py"
  }
  source {
    content  = file("${path.module}/../functions/shared/gemini_client.py")
    filename = "gemini_client.py"
  }
  source {
    content  = file("${path.module}/../functions/shared/__init__.py")
    filename = "__init__.py"
  }
}

# Upload get_words source
resource "google_storage_bucket_object" "get_words_source" {
  name   = "get_words-${data.archive_file.get_words_source.output_md5}.zip"
  bucket = google_storage_bucket.functions_bucket.name
  source = data.archive_file.get_words_source.output_path
}

# Upload generate_words source
resource "google_storage_bucket_object" "generate_words_source" {
  name   = "generate_words-${data.archive_file.generate_words_source.output_md5}.zip"
  bucket = google_storage_bucket.functions_bucket.name
  source = data.archive_file.generate_words_source.output_path
}

# Cloud Function: get_words (Gen 2)
resource "google_cloudfunctions2_function" "get_words" {
  name     = "get-words"
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "get_words"

    source {
      storage_source {
        bucket = google_storage_bucket.functions_bucket.name
        object = google_storage_bucket_object.get_words_source.name
      }
    }
  }

  service_config {
    max_instance_count    = 10
    min_instance_count    = 0
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = google_service_account.functions_sa.email

    environment_variables = {
      GCP_PROJECT = var.project_id
    }
  }

  depends_on = [
    google_project_service.cloudfunctions,
    google_project_service.run,
    google_project_service.cloudbuild
  ]
}

# Cloud Function: generate_words (Gen 2)
resource "google_cloudfunctions2_function" "generate_words" {
  name     = "generate-words"
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "generate_words"

    source {
      storage_source {
        bucket = google_storage_bucket.functions_bucket.name
        object = google_storage_bucket_object.generate_words_source.name
      }
    }
  }

  service_config {
    max_instance_count    = 1
    min_instance_count    = 0
    available_memory      = "512M"
    timeout_seconds       = 300
    service_account_email = google_service_account.functions_sa.email

    environment_variables = {
      GCP_PROJECT = var.project_id
    }
  }

  depends_on = [
    google_project_service.cloudfunctions,
    google_project_service.run,
    google_project_service.cloudbuild,
    google_project_service.aiplatform
  ]
}

# Allow unauthenticated access to get_words
resource "google_cloud_run_service_iam_member" "get_words_invoker" {
  location = google_cloudfunctions2_function.get_words.location
  service  = google_cloudfunctions2_function.get_words.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Cloud Scheduler job to trigger generate_words daily at 0:00 JST
resource "google_cloud_scheduler_job" "generate_words_daily" {
  name             = "goiryoku-generate-words-daily"
  description      = "Trigger word generation daily at 0:00 JST"
  schedule         = "0 0 * * *"
  time_zone        = "Asia/Tokyo"
  attempt_deadline = "320s"

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions2_function.generate_words.service_config[0].uri

    oidc_token {
      service_account_email = google_service_account.functions_sa.email
    }
  }

  depends_on = [google_project_service.cloudscheduler]
}
