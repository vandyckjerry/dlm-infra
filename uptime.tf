resource "google_monitoring_uptime_check_config" "dlm_https" {
  project = var.project_id
  display_name = "https://delaatsteminuut.be uptime check"
  timeout = "10s"
  period = "60s"

  selected_regions = ["EUROPE", "USA"]

  http_check {
    path = "/"
    port = "443"
    use_ssl = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host = var.production_url
    }
  }
  content_matchers {
    content = "vakantieblog"
  }
}

resource "google_monitoring_uptime_check_config" "dlm_https_www" {
  project = var.project_id
  display_name = "https://www.delaatsteminuut.be uptime check"
  timeout = "10s"
  period = "60s"

  selected_regions = ["EUROPE", "USA"]

  http_check {
    path = "/"
    port = "443"
    use_ssl = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host = var.www_production_url
    }
  }
  content_matchers {
    content = "vakantieblog"
  }
}
