variable "project_id" {
    default     = "cloud-function-371409"
    type        = string
    description = "Project ID"
}

variable "region" {
    default     = "us-central1"
    type        = string
    description = "Region"
}

variable "dataset_id" {
    default     = "task_cf_dataset"
    type        = string
    description = "Dataset ID"
}

variable "table_id" {
    default     = "task_cf_table"
    type        = string
    description = "Table dataflow task ID"
}

variable "pubsub_topic_name" {
  default = "cf_pubsub_topic"
  type = string
}

variable "subscription_name" {
  default = "cf_pubsub_subscrp"
  type = string
}

variable "deletion_protection" {
  default = false
}