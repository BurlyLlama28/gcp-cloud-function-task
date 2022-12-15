terraform {
  backend "gcs" {
    prefix = "cf/task-cf"
  }
}

locals {
  env          = substr(var.project_id, -3, -1)
}

module "task_cf_function" {
  project_id          = var.project_id
  name                = "task_cf_function"
  source_directory    = "function"
  function_type       = "http"
  available_memory_mb = 256
  timeout_s           = 540
  entry_point         = "main"
  runtime             = "python38"
  public_function     = true

  environment_variables = {
    BDE_GCP_PROJECT = var.project_id
    OUTPUT_TABLE    = "data_set_name.task-cf-data"
    FUNCTION_REGION = "europe-west1"
  }
}

module "task_cf_dataset" {
  project_id = var.project_id
  dataset_id = "data_set_name"
  tables = {
    task-cf-data = {
      schema                   = file("schemas/task-cf-raw.json")
      require_partition_filter = true
      time_partitioning_field  = "timestamp"
      time_partitioning_type   = "DAY"
    }
  }
}

variable "project_id" {
  type        = string
  description = "Project ID to deploy resources in."
}
