resource "google_storage_bucket" "dlm_static" {
  name = "dlm-static"
  location = var.location
  project = var.project_id
  bucket_policy_only = true
  cors {
    origin = ["*"]
    method = ["GET"]
  }
}

resource "google_storage_bucket_iam_member" "dlm_static_public_access" {
  bucket = google_storage_bucket.dlm_static.name
  role = "roles/storage.objectViewer"
  member = "allUsers"
}


resource "google_storage_bucket" "dlm_static_production" {
  name = "dlm-static-production"
  location = var.location
  project = var.project_id
  bucket_policy_only = true
  cors {
    origin = ["*"]
    method = ["GET"]
  }
}

resource "google_storage_bucket_iam_member" "dlm_static_public_access_production" {
  bucket = google_storage_bucket.dlm_static_production.name
  role = "roles/storage.objectViewer"
  member = "allUsers"
}

