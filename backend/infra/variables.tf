variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Functions"
  type        = string
  default     = "asia-northeast1"
}

variable "firestore_location" {
  description = "Firestore database location"
  type        = string
  default     = "asia-northeast1"
}
