resource "google_cloudbuild_trigger" "dlm_php_app" {
  project = var.project_id
  provider = google-beta
  github {
    owner = "codeMonkeysBe"
    name = "delaatsteminuut"
    pull_request {
      branch = ".*"
    }
  }
  build {
    images = [ "eu.gcr.io/$PROJECT_ID/dlm:$SHORT_SHA"]

    step {
      env = [
        "ADMIN_HOST=admin.default.svc.cluster.local",
        "WEB_HOST=dlm.default.svc.cluster.local",
        "STATIC_PATH=https://storage.googleapis.com/dlm-static/",
        "DB_NAME=dlm-mysql-development"
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
        "DB_NAME=${google_sql_database.dlm_mysql_development.name}"
      ]
      name = "eu.gcr.io/$PROJECT_ID/dlm:$SHORT_SHA"
      entrypoint = "bash"
      args = [ "script/upgrade.sh" ]
    }

    step {
      name = "gcr.io/cloud-builders/gke-deploy"
      args = [
        "run",
        "--filename", "config/deployments/shared/",
        "--location", var.zone,
        "--cluster", google_container_cluster.dlm.name
      ]
    }

    step {
      name = "gcr.io/cloud-builders/gke-deploy"
      args = [
        "run",
        "--image", "eu.gcr.io/$PROJECT_ID/dlm:$SHORT_SHA",
        "--filename", "config/deployments/development/",
        "--location", var.zone,
        "--cluster", google_container_cluster.dlm.name,
        "--output", "./env_output"
      ]
    }


  }

}

resource "google_cloudbuild_trigger" "dlm-static_repo_trigger" {
  project = var.project_id
  provider = google-beta
  github {
    owner = "codeMonkeysBe"
    name = "dlm-static"
    pull_request {
      branch = ".*"
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
      args = [ "-m", "-h", "Cache-Control:public,max-age=31536000", "cp", "-r", "-z", "js,css","/workspace/dist/*", "${google_storage_bucket.dlm_static.url}/"]
    }
  }

}

resource "google_cloudbuild_trigger" "dlm-admin_repo_trigger" {
  project = var.project_id
  provider = google-beta
  github {
    owner = "codeMonkeysBe"
    name = "dlm-admin"
    pull_request {
      branch = ".*"
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
        "--location", var.zone,
        "--cluster", google_container_cluster.dlm.name
      ]
    }

  }

}
