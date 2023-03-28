resource "google_cloudbuild_trigger" "dlm_php_app_production" {
  project = var.project_id
  provider = google-beta
  github {
    owner = "codeMonkeysBe"
    name = "delaatsteminuut"
    push {
      branch = "master"
    }
  }
  build {
    images = [ "eu.gcr.io/$PROJECT_ID/dlm:$SHORT_SHA"]

    step {
      env = [
        "ADMIN_HOST=admin.production.svc.cluster.local",
        "WEB_HOST=dlm.production.svc.cluster.local",
        "STATIC_PATH=https://storage.googleapis.com/dlm-static-production/",
        "DB_NAME=dlm-mysql-production"
      ]
      name = "gcr.io/cloud-builders/docker"
      args = [ "build",
        "-t", "eu.gcr.io/$PROJECT_ID/dlm:$SHORT_SHA",
        "--build-arg", "ADMIN_HOST",
        "--build-arg", "STATIC_PATH",
        "--build-arg", "DB_NAME",
        "--build-arg", "WEB_HOST"
      ,  "."]
    }

    step {
      name = "gcr.io/cloud-builders/docker"
      args = [ "push", "eu.gcr.io/$PROJECT_ID/dlm:$SHORT_SHA"]
    }

    step {
      env = [
        "CLOUD_SQL_CONNECTION_NAME=${var.project_id}:${var.location}:${google_sql_database_instance.dlm_mysql_instance.name}",
        "DB_NAME=${google_sql_database.dlm_mysql_production.name}"
      ]
      name = "eu.gcr.io/$PROJECT_ID/dlm:$SHORT_SHA"
      entrypoint = "bash"
      args = [ "script/upgrade.sh" ]
    }

    step {
      name = "gcr.io/cloud-builders/gke-deploy"
      args = [
        "run",
        "--namespace", "production",
        "--cluster", google_container_cluster.dlm.name,
        "--filename", "config/deployments/shared/",
        "--location", var.zone,
      ]
    }

    step {
      name = "gcr.io/cloud-builders/gke-deploy"
      args = [
        "run",
        "--image", "eu.gcr.io/$PROJECT_ID/dlm:$SHORT_SHA",
        "--namespace", "production",
        "--cluster", google_container_cluster.dlm.name,
        "--filename", "config/deployments/production/",
        "--location", var.zone,
        "--output", "./env_output",
      ]
    }

  }

}

resource "google_cloudbuild_trigger" "dlm-static_repo_trigger_production" {
  project = var.project_id
  provider = google-beta
  github {
    owner = "codeMonkeysBe"
    name = "dlm-static"
    push {
      branch = "master"
    }
  }
  build {
    images = [ "eu.gcr.io/$PROJECT_ID/dlm-static:$SHORT_SHA"]

    step {
      name = "gcr.io/cloud-builders/docker"
      args = [ "build", "-t", "eu.gcr.io/$PROJECT_ID/dlm-static:$SHORT_SHA", "."]
    }
    step {
      name = "gcr.io/cloud-builders/docker"
      args = [ "push", "eu.gcr.io/$PROJECT_ID/dlm-static:$SHORT_SHA"]
    }
    step {
      name = "eu.gcr.io/$PROJECT_ID/dlm-static:$SHORT_SHA"
      entrypoint = "npm"
      args = ["run", "copy-to-workspace"]
    }
   step {
      name = "gcr.io/cloud-builders/gsutil"
      args = [ "-m", "-h", "Cache-Control:public,max-age=31536000", "cp", "-r", "-z", "js,css","/workspace/dist/*", "${google_storage_bucket.dlm_static_production.url}/"]
    }
  }

}

resource "google_cloudbuild_trigger" "dlm-admin_repo_trigger_production" {
  project = var.project_id
  provider = google-beta
  github {
    owner = "codeMonkeysBe"
    name = "dlm-admin"
    push {
      branch = "master"
    }
  }
  build {
    images = [
      "eu.gcr.io/$PROJECT_ID/dlm-admin:$SHORT_SHA"]

    step {
      name = "gcr.io/cloud-builders/docker"
      args = [ "build", "-t", "eu.gcr.io/$PROJECT_ID/dlm-admin:$SHORT_SHA", "."]
    }
    step {
      name = "gcr.io/cloud-builders/docker"
      args = [ "push", "eu.gcr.io/$PROJECT_ID/dlm-admin:$SHORT_SHA"]
    }
    step {
      name = "gcr.io/cloud-builders/gke-deploy"
      args = [
        "run",
        "--image", "eu.gcr.io/$PROJECT_ID/dlm-admin:$SHORT_SHA",
        "--filename", "deployments/k8s/deployment.yaml",
        "--namespace", "production",
        "--cluster", google_container_cluster.dlm.name,
        "--location", var.zone,
      ]
    }

  }

}
