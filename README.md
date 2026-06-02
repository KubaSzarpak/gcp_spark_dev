# Mini klaster Apache Spark na GCP

Projekt szkoleniowy DevOps — mini klaster **Apache Spark** na **Google Cloud Platform** zarządzany przez **Terraform**.

## Stack

| Warstwa | Technologia |
|---|---|
| IaC | Terraform >= 1.5, provider `hashicorp/google ~> 5.0` |
| Sieć | VPC, subnet, firewall (bez publicznych IP, IAP Tunnel) |
| Obliczenia | GCP Dataproc (Spark 3.4 / obraz `2.1-debian12`) |
| Pamięć | Cloud Storage (staging bucket + data bucket) |
| Region | `europe-central2` (Warszawa) |

## Architektura

```
┌───────────────────────────────────────┐
│             GCP Project               │
│  ┌────────────────────────────────┐   │
│  │             VPC                │   │
│  │  ┌──────────────────────────┐  │   │
│  │  │  Subnet 10.10.0.0/24    │  │   │
│  │  │                          │  │   │
│  │  │  ┌────────────────────┐  │  │   │
│  │  │  │  Dataproc Cluster  │  │  │   │
│  │  │  │  Master + 2 Worker │  │  │   │
│  │  │  └────────┬───────────┘  │  │   │
│  │  └───────────│──────────────┘  │   │
│  └──────────────│─────────────────┘   │
│                 │                     │
│  ┌──────────────▼─────────────────┐   │
│  │       Cloud Storage (GCS)      │   │
│  │  spark-staging-*  spark-data-* │   │
│  └────────────────────────────────┘   │
└───────────────────────────────────────┘
```

**Klaster w liczbach:**
- Master: `n1-standard-2` — 2 vCPU, 7.5 GB RAM
- 2x Worker: `n1-standard-2` — 2 vCPU, 7.5 GB RAM każdy
- Łącznie: 6 vCPU | ~22.5 GB RAM

## Struktura projektu

```
gcp_spark/
├── terraform/
│   ├── main.tf              ← root module (provider, API, łączy moduły)
│   ├── variables.tf         ← parametry wejściowe
│   ├── outputs.tf           ← wartości po apply (np. polecenie SSH tunnel)
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── network/         ← VPC, subnet, firewall
│       ├── storage/         ← buckety GCS, service account
│       └── dataproc/        ← klaster Spark
└── scripts/
    ├── word_count.py        ← przykładowy job PySpark
    └── submit_job.sh        ← skrypt do uruchomienia joba
```

## Wymagania wstępne

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) z aktywną sesją (`gcloud auth application-default login`)
- Projekt GCP z włączonymi płatnościami
- Bucket GCS na backend Terraform state

## Szybki start

### 1. Konfiguracja zmiennych

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edytuj terraform.tfvars — uzupełnij project_id
```

### 2. Inicjalizacja i wdrożenie

```bash
terraform init -backend-config="bucket=<TWOJ_BUCKET_NA_STATE>"
terraform plan
terraform apply
```

Klaster jest gotowy po ~2 minutach.

### 3. Uruchomienie przykładowego joba

```bash
# Pobierz nazwę data bucketu z outputów Terraform
DATA_BUCKET=$(terraform output -raw data_bucket)

cd ..
./scripts/submit_job.sh <PROJECT_ID> europe-central2 spark-training-cluster "$DATA_BUCKET"
```

Wyniki pojawią się w `gs://<data-bucket>/output/`.

### 4. Spark UI przez SSH tunnel

```bash
# Polecenie z outputu Terraform:
terraform output spark_ui_port_forward
```

- `localhost:4040` — Spark UI (joby, DAG, executory)
- `localhost:8080` — YARN ResourceManager

### 5. Usunięcie klastra

```bash
terraform destroy
```

> **Koszt:** klaster kosztuje ~$0.28/h nawet bezczynny. Konfiguracja zawiera `idle_delete_ttl = 3600s` — klaster wyłącza się automatycznie po 1h bez aktywności.

## Zmienne Terraform

| Zmienna | Domyślna | Opis |
|---|---|---|
| `project_id` | — | ID projektu GCP (wymagana) |
| `region` | `europe-central2` | Region GCP |
| `zone` | `europe-central2-a` | Strefa GCP |
| `env` | `dev` | Środowisko (dev / staging / prod) |
| `cluster_name` | `spark-training-cluster` | Nazwa klastra Dataproc |
| `num_workers` | `2` | Liczba węzłów worker |
| `master_machine` | `n1-standard-2` | Typ maszyny mastera |
| `worker_machine` | `n1-standard-2` | Typ maszyny workerów |
| `spark_version` | `2.1-debian12` | Obraz Dataproc (Spark 3.4, Hadoop 3.3) |

## Outputy Terraform

| Output | Opis |
|---|---|
| `cluster_name` | Nazwa klastra Dataproc |
| `master_instance_name` | Nazwa VM mastera |
| `staging_bucket` | Bucket GCS dla Dataproc |
| `data_bucket` | Bucket GCS na dane i wyniki |
| `spark_ui_port_forward` | Gotowe polecenie SSH tunnel do Spark UI |

## CI/CD

Projekt zawiera przykład pipeline GitHub Actions (`github_actions_prezentacja.md`). Backend Terraform state na GCS — bucket i prefix przekazywane przez `-backend-config` w CI.

## Materiały szkoleniowe

- `prezentacja.md` — slajdy szkolenia: Terraform, GCP, architektura Spark, demo
- `prezentacja_gcloud_login.md` — krok po kroku: logowanie gcloud
- `prezentacja_iac_claude.md` — IaC z pomocą AI

## Test commit
Test push to trigger GitHub Actions (2026-06-02)
