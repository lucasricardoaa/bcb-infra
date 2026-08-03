# Módulo Glue — Data Catalog databases, tabelas e Glue Job
#
# Recursos importados do bcb-pipeline (já existem na AWS):
#   - aws_glue_catalog_database.pipeline   (bcb_pipeline)
#   - aws_glue_catalog_table.usd_brl       (bcb_pipeline:usd_brl)
#   - aws_glue_catalog_table.selic         (bcb_pipeline:selic)
#   - aws_glue_catalog_table.ipca          (bcb_pipeline:ipca)
#
# Recursos novos do bcb-warehouse:
#   - aws_glue_catalog_database.warehouse  (bcb_warehouse)
#   - aws_glue_job.staging_transform       (bcb-staging-transform)

# ---------------------------------------------------------------------------
# Glue Catalog Database — bcb_pipeline (import)
# ---------------------------------------------------------------------------

resource "aws_glue_catalog_database" "pipeline" {
  name = "bcb_pipeline"

  # create_table_default_permission é gerenciado pelo Glue automaticamente.
  # O bloco abaixo reflete exatamente o que está na AWS para evitar diff no plan.
  create_table_default_permission {
    permissions = ["ALL"]
    principal {
      data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
    }
  }
}

# ---------------------------------------------------------------------------
# Glue Catalog Tables — bcb_pipeline (import)
# ---------------------------------------------------------------------------

resource "aws_glue_catalog_table" "usd_brl" {
  name          = "usd_brl"
  database_name = aws_glue_catalog_database.pipeline.name

  table_type = "EXTERNAL_TABLE"
  owner      = "hadoop"

  parameters = {
    "parquet.compress"      = "SNAPPY"
    "EXTERNAL"              = "TRUE"
    "transient_lastDdlTime" = "1784311274"
  }

  lifecycle {
    ignore_changes = [parameters]
  }

  storage_descriptor {
    location          = "s3://bcb-pipeline-staging/bcb/1"
    input_format      = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format     = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    compressed        = false
    number_of_buckets = -1
    stored_as_sub_directories = false

    columns {
      name = "data"
      type = "date"
    }

    columns {
      name = "valor"
      type = "double"
    }

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }

    skewed_info {
      skewed_column_names               = []
      skewed_column_values              = []
      skewed_column_value_location_maps = {}
    }
  }
}

resource "aws_glue_catalog_table" "selic" {
  name          = "selic"
  database_name = aws_glue_catalog_database.pipeline.name

  table_type = "EXTERNAL_TABLE"
  owner      = "hadoop"

  parameters = {
    "parquet.compress"      = "SNAPPY"
    "EXTERNAL"              = "TRUE"
    "transient_lastDdlTime" = "1784311290"
  }

  lifecycle {
    ignore_changes = [parameters]
  }

  storage_descriptor {
    location          = "s3://bcb-pipeline-staging/bcb/11"
    input_format      = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format     = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    compressed        = false
    number_of_buckets = -1
    stored_as_sub_directories = false

    columns {
      name = "data"
      type = "date"
    }

    columns {
      name = "valor"
      type = "double"
    }

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }

    skewed_info {
      skewed_column_names               = []
      skewed_column_values              = []
      skewed_column_value_location_maps = {}
    }
  }
}

resource "aws_glue_catalog_table" "ipca" {
  name          = "ipca"
  database_name = aws_glue_catalog_database.pipeline.name

  table_type = "EXTERNAL_TABLE"
  owner      = "hadoop"

  parameters = {
    "parquet.compress"      = "SNAPPY"
    "EXTERNAL"              = "TRUE"
    "transient_lastDdlTime" = "1784311300"
  }

  lifecycle {
    ignore_changes = [parameters]
  }

  storage_descriptor {
    location          = "s3://bcb-pipeline-staging/bcb/433"
    input_format      = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format     = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    compressed        = false
    number_of_buckets = -1
    stored_as_sub_directories = false

    columns {
      name = "data"
      type = "date"
    }

    columns {
      name = "valor"
      type = "double"
    }

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }

    skewed_info {
      skewed_column_names               = []
      skewed_column_values              = []
      skewed_column_value_location_maps = {}
    }
  }
}

# ---------------------------------------------------------------------------
# Glue Catalog Database — bcb_warehouse (novo)
# ---------------------------------------------------------------------------

resource "aws_glue_catalog_database" "warehouse" {
  name = "bcb_warehouse"

  tags = {
    Project   = "bcb-warehouse"
    ManagedBy = "bcb-infra"
  }
}

# ---------------------------------------------------------------------------
# Glue Job — bcb-staging-transform (novo)
# Lê da camada staging do bcb-pipeline e escreve no bcb-warehouse em Iceberg.
# ---------------------------------------------------------------------------

resource "aws_glue_job" "staging_transform" {
  name     = "bcb-staging-transform"
  role_arn = var.glue_role_arn

  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  timeout           = 10 # minutos — default 2880 (48h) representa risco de ~$42 se o job travar

  command {
    name            = "glueetl"
    script_location = "s3://bcb-warehouse/glue/scripts/bcb_staging_transform.py"
    python_version  = "3"
  }

  default_arguments = {
    "--datalake-formats" = "iceberg"
    "--conf" = join(",", [
      "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
      "spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog",
      "spark.sql.catalog.glue_catalog.warehouse=s3://bcb-warehouse/iceberg/",
      "spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog",
      "spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO"
    ])
    "--TempDir"                          = "s3://bcb-warehouse/glue/temp/"
    "--spark-event-logs-path"            = "s3://bcb-warehouse/glue/logs/"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-glue-datacatalog"          = "true"
    "--job-language"                     = "python"
  }

  tags = {
    Project   = "bcb-warehouse"
    ManagedBy = "bcb-infra"
  }
}
