terraform {
  backend "gcs" {
    bucket = "df-storage-task"
    prefix = "df-task"
  }
}


provider "google" {

  project = var.project_id
  region  = var.region
}

#IAM stuff
resource "google_project_iam_member" "project-me" {
  project = var.project_id
  role    = "roles/owner"
  member  = "user:kiltik12@gmail.com"
}

resource "google_project_iam_member" "project-cloud-build" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

# data "google_project" "project" {

# }

# data "archive_file" "source" {
#     type        = "zip"
#     source_dir  = "../function"
#     output_path = "/tmp/function.zip"
# }


resource "google_storage_bucket" "task-df-storage-bucket" {
  name     = "${var.project_id}-df-storage-bucket"
  location = var.region
}

resource "google_storage_bucket_object" "task-df-bucket-object" {
    source       = data.archive_file.source.output_path
    content_type = "application/zip"

    name         = "src-${data.archive_file.source.output_md5}.task-df-bucket-object"
    bucket       = google_storage_bucket.task-df-storage-bucket.name

    depends_on   = [
        google_storage_bucket.task-df-storage-bucket,
        data.archive_file.source
    ]
}

resource "google_bigquery_dataset" "task_df_dataset" {
  dataset_id = var.dataset_id
  description = "Public dataset for df-task"

  location = var.location
}

resource "google_bigquery_table" "df_usual_messages_table" {
  dataset_id = var.dataset_id
  table_id   = var.table_id
  schema = file("../schemas/bq_table_schema/task_df_raw.json")

  depends_on = [
    google_bigquery_dataset.task_df_dataset
  ]
}

resource "google_bigquery_table" "df_error_messages_table" {
  dataset_id = var.dataset_id
  table_id   = var.table_error_id
  schema = file("../schemas/bq_table_schema/task_df_error_raw.json")

  depends_on = [
    google_bigquery_dataset.task_df_dataset
  ]
}

resource "google_dataflow_job" "big_data_job" {
  name                  = "dataflow-job"
  template_gcs_path     = "gs://cloud-function-371409-dataflow-bucket/template/dataflow-job"
  temp_gcs_location     = "gs://cloud-function-371409-dataflow-bucket/tmp"
  service_account_email = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}