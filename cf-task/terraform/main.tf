terraform {
  backend "gcs" {
    bucket = "cf-storage-task"
    prefix = "cf-task"
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
  #  member = data.google_service_account.cloudbuild_account.name
}

data "google_project" "project" {

}

data "archive_file" "source" {
    type        = "zip"
    source_dir  = "../function"
    output_path = "/tmp/function.zip"
}


resource "google_storage_bucket" "task-cf-storage-bucket" {
  name     = "${var.project_id}-storage-bucket"
  location = var.region
}

resource "google_bigquery_dataset" "task_cf_dataset" {
  dataset_id = var.dataset_id
  description = "Public dataset for cf-task"

  location = var.location
}

resource "google_bigquery_table" "task_cf_table" {
  dataset_id = google_bigquery_dataset.task_cf_dataset.dataset_id
  table_id   = var.table_id
  schema = file("../schemas/bq_table_schema/task-cf-raw.json")
}

resource "google_pubsub_topic" "topic" {
  name = var.pubsub_topic_name
}

resource "google_pubsub_subscription" "subscription" {
  name  = var.subscription_name
  topic = google_pubsub_topic.topic.name
}

resource "google_storage_bucket_object" "zip" {
    source       = data.archive_file.source.output_path
    content_type = "application/zip"

    name         = "func-${data.archive_file.source.output_md5}.zip"
    bucket       = google_storage_bucket.task-cf-storage-bucket.name

    depends_on   = [
        google_storage_bucket.task-cf-storage-bucket,
        data.archive_file.source
    ]
}

resource "google_cloudbuild_trigger" "github-trigger" {
  project = var.project_id
  name = "cf-update-trigger"
  filename = "cloudbuild.yaml"
  github {
    owner = "BurlyLlama28"
    name = "gcp-cloud-function-task"
    push {
      branch = "^main"
    }
  }
}

resource "google_cloudfunctions_function" "task-cf-function" {
    name                  = "task-cf-function"
    runtime               = "python39"

    source_archive_bucket = google_storage_bucket.task-cf-storage-bucket.name
    source_archive_object = google_storage_bucket_object.zip.name

    entry_point           = "main"
    trigger_http          = true

    environment_variables = {
      GCP_PROJECT = var.project_id
      DATASET_ID = var.dataset_id
      OUTPUT_TABLE = google_bigquery_table.task_cf_table.table_id
      TOPIC_ID = var.pubsub_topic_name
    }

    # depends_on            = [
    #     google_storage_bucket.task-cf-storage-bucket,
    #     google_storage_bucket_object.zip
    # ]
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.task-cf-function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}