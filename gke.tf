data "google_client_config" "current" {
}

terraform {
  required_providers {
    kubernetes  = "~> 1.10.0"
  }
}

provider "kubernetes" {
  load_config_file = false
  host = "https://${google_container_cluster.dlm.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.dlm.master_auth.0.cluster_ca_certificate)
  token = data.google_client_config.current.access_token
}

resource "google_container_cluster" "dlm" {
  name     = "dlm"
  location = var.zone
  project = var.project_id

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
  min_master_version = "1.16.13-gke.401"

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
  lifecycle {
    create_before_destroy = true
  }
  maintenance_policy {
    daily_maintenance_window {
      start_time = "00:00"
    }
  }
}

resource "google_container_node_pool" "dlm" {
  name       = "dlm"
  location   = var.zone
  cluster    = google_container_cluster.dlm.name
  node_count = 2
  project = var.project_id

  node_config {
    machine_type = "n1-standard-1"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "compute-rw",
      "storage-ro",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "google_compute_global_address" "ingress_ip" {
  project = var.project_id
  name = "dlm-ingress-ip"
}

resource "google_compute_global_address" "ingress_ip_production" {
  project = var.project_id
  name = "dlm-ingress-ip-production"
}


resource "google_service_account" "gke_app_sa" {
  account_id = "dlm-app-sa"
  display_name = "DLM App Service Account"
  project = var.project_id
}

resource "google_project_iam_member" "gke_storage" {
  project = var.project_id
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.gke_app_sa.email}"
}

resource "google_project_iam_member" "gke_app_sql" {
  project = var.project_id
  role = "roles/cloudsql.client"
  member = "serviceAccount:${google_service_account.gke_app_sa.email}"
}

resource "google_service_account_key" "cloudsql_instance_credentials" {
  service_account_id = google_service_account.gke_app_sa.name
}

resource "kubernetes_secret" "cloudsql_instance_credentials" {
  metadata {
    name = "cloudsql-instance-credentials"
  }
  data = {
    "credentials.json" = base64decode(google_service_account_key.cloudsql_instance_credentials.private_key)
  }
}

resource "kubernetes_namespace" "production" {
  metadata {
    name = "production"
  }
}

resource "kubernetes_secret" "cloudsql_instance_credentials_production" {
  metadata {
    name = "cloudsql-instance-credentials"
    namespace = kubernetes_namespace.production.metadata[0].name
  }
  data = {
    "credentials.json" = base64decode(google_service_account_key.cloudsql_instance_credentials.private_key)
  }
}

