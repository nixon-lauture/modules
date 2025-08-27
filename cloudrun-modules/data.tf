data "google_secret_manager_secret_version" "db_user" {
  secret  = "DB_USER"
  project = var.project_id
  version = "latest"
}

data "google_secret_manager_secret_version" "db_pass" {
  secret  = "DB_PASS"
  project = var.project_id
  version = "latest"
}

data "google_secret_manager_secret_version" "db_name" {
  secret  = "DB_NAME"
  project = var.project_id

  version = "latest"
}

data "google_secret_manager_secret_version" "github_token" {
  secret  = "GITHUB_ACCESS_TOKEN"
  project = var.project_id

  version = "latest"
}
data "google_secret_manager_secret_version" "openai_api" {
  secret  = "OPENAI_API_KEY"
  project = var.project_id
  version = "latest"
}

data "google_secret_manager_secret_version" "openai_organization" {
  secret  = "OPENAI_ORGANIZATION"
  project = var.project_id
  version = "latest"
}

data "google_secret_manager_secret_version" "secret_key_access_api" {
  secret  = "SECRET_KEY_ACCESS_API"
  project = var.project_id
  version = "latest"
}
