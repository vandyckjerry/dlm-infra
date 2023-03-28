variable "location" {
  default = "europe-west1"
}
variable "zone" {
  default = "europe-west1-d"
}
variable "project_id" {
  default = "delaatsteminuut"
}

variable "development_url"  {
  default = "delaatsteminuut.waasit.be"
}

variable "production_url"  {
  default = "delaatsteminuut.be"
}

variable "www_production_url"  {
  default = "www.delaatsteminuut.be"
}

provider "google-beta" {
  project = var.project_id
  region = var.location
  zone = var.zone
}

data "google_project" "dlm" {
  project_id = var.project_id

}
