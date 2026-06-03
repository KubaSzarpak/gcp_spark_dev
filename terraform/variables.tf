variable "project_id" {
  description = "ID projektu GCP"
  type        = string
}

variable "region" {
  description = "Region GCP (np. europe-central2 = Warszawa)"
  type        = string
  default     = "europe-central2"
}

variable "zone" {
  description = "Strefa GCP"
  type        = string
  default     = "europe-central2-a"
}

variable "env" {
  description = "Środowisko (dev / staging / prod)"
  type        = string
  default     = "dev"
}

variable "network_name" {
  description = "Nazwa sieci VPC"
  type        = string
  default     = "spark-vpc"
}

variable "cluster_name" {
  description = "Nazwa klastra Dataproc"
  type        = string
  default     = "spark-training-cluster"
}

variable "master_machine" {
  description = "Typ maszyny dla mastera"
  type        = string
  default     = "n1-standard-2" # 2 vCPU / 7.5 GB RAM – tanie szkoleniowo
}

variable "worker_machine" {
  description = "Typ maszyny dla workerów"
  type        = string
  default     = "n1-standard-2"
}

variable "num_workers" {
  description = "Liczba węzłów worker"
  type        = number
  default     = 2
}

variable "spark_version" {
  description = "Wersja obrazu Dataproc (Spark + Hadoop)"
  type        = string
  default     = "2.1-debian12" # Spark 3.4, Hadoop 3.3
}
