resource "google_project_iam_member" "gke_developer" {
  project = var.project_id
  role = "roles/container.developer"
  member = "serviceAccount:${data.google_project.dlm.number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "sa_user" {
  project = var.project_id
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${data.google_project.dlm.number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "sql_admin" {
  project = var.project_id
  role = "roles/cloudsql.admin"
  member = "serviceAccount:${data.google_project.dlm.number}@cloudbuild.gserviceaccount.com"
}
