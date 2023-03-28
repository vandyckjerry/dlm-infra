resource "google_sql_database_instance" "dlm_mysql_instance" {
  name = "dlm-mysql-instance-5-7"
  region = var.location
  project = var.project_id
  database_version = "MYSQL_5_7"
  settings {
    tier = "db-n1-standard-1"
    database_flags {
      name = "sql_mode"
      value = "TRADITIONAL"
    }
    backup_configuration {
      binary_log_enabled = true
      enabled = true
      start_time = "22:00"

    }
  }
}

resource "google_sql_user" "dlm_mysql_user" {
  name = "delaatsteminuut"
  instance = google_sql_database_instance.dlm_mysql_instance.name
  password = "delaatsteminuut"
  project = var.project_id
}

resource "google_sql_database" "dlm_mysql_production" {
  name = "dlm-mysql-production"
  instance = google_sql_database_instance.dlm_mysql_instance.name
  project = var.project_id
}

resource "google_sql_database" "dlm_mysql_development" {
  name = "dlm-mysql-development"
  instance = google_sql_database_instance.dlm_mysql_instance.name
  project = var.project_id
}

