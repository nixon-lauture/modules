data "google_project" "current" {}

# Create ZIP files for function source code
data "archive_file" "api_processor_zip" {
  type        = "zip"
  output_path = "${path.module}/api_processor.zip"
  source_dir  = "${path.module}/functions/api_processor"
}

data "archive_file" "data_processor_zip" {
  type        = "zip"
  output_path = "${path.module}/data_processor.zip"
  source_dir  = "${path.module}/functions/data_processor"
}
