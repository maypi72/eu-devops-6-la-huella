#!/usr/bin/env bash
set -e
export AWS_PAGER=""

REGION="eu-west-1"
ENDPOINT="http://localhost:4566"

echo "🚀 Inicializando recursos en LocalStack..."
echo "Endpoint: $ENDPOINT"
echo "Region: $REGION"
echo

echo "=== Creando buckets S3 ==="
create_bucket_if_not_exists() {
  local bucket=$1

  if awslocal s3api head-bucket --bucket "$bucket" >/dev/null 2>&1; then
    echo "⚠️  Bucket ya existe: $bucket (saltando)"
  else
    echo "✅ Creando bucket: $bucket"
    awslocal s3 mb "s3://$bucket" --no-cli-pager
  fi
}

create_bucket_if_not_exists "la-huella-sentiment-reports"
create_bucket_if_not_exists "la-huella-uploads"

echo
# ============================
# BUCKET POLICY
# ============================
echo "=== Aplicando política al bucket la-huella-uploads ==="

if awslocal s3api get-bucket-policy --bucket la-huella-uploads >/dev/null 2>&1; then
  echo "⚠️  Bucket policy ya aplicada en la-huella-uploads (saltando)"
else
  echo "✅ Aplicando bucket policy..."
  awslocal s3api put-bucket-policy --bucket la-huella-uploads --policy file://public-read-policy.json --no-cli-pager
fi

echo
echo "=== Creando tablas DynamoDB ==="
create_table_if_not_exists() {
  local table=$1
  shift

  if awslocal dynamodb describe-table --table-name "$table" >/dev/null 2>&1; then
    echo "⚠️  Tabla ya existe: $table (saltando)"
  else
    echo "✅ Creando tabla: $table"

    "$@"

    echo "⏳ Esperando a que la tabla $table exista..."
    awslocal dynamodb wait table-exists --table-name "$table"
    echo "✅ Tabla lista: $table"
  fi
}

# Tabla 1: la-huella-comments
create_table_if_not_exists "la-huella-comments" \
  awslocal dynamodb create-table \
    --table-name la-huella-comments \
    --attribute-definitions \
      AttributeName=id,AttributeType=S \
      AttributeName=productId,AttributeType=S \
      AttributeName=createdAt,AttributeType=S \
    --key-schema \
      AttributeName=id,KeyType=HASH \
    --global-secondary-indexes '[
      {
        "IndexName": "ProductIndex",
        "KeySchema": [
          {"AttributeName":"productId","KeyType":"HASH"},
          {"AttributeName":"createdAt","KeyType":"RANGE"}
        ],
        "Projection": {"ProjectionType":"ALL"}
      }
    ]' \
    --billing-mode PAY_PER_REQUEST \
    --no-cli-pager

# Tabla 2: la-huella-products
create_table_if_not_exists "la-huella-products" \
  awslocal dynamodb create-table \
    --table-name la-huella-products \
    --attribute-definitions \
      AttributeName=id,AttributeType=S \
      AttributeName=category,AttributeType=S \
    --key-schema \
      AttributeName=id,KeyType=HASH \
    --global-secondary-indexes '[
      {
        "IndexName": "CategoryIndex",
        "KeySchema": [
          {"AttributeName":"category","KeyType":"HASH"}
        ],
        "Projection": {"ProjectionType":"ALL"}
      }
    ]' \
    --billing-mode PAY_PER_REQUEST \
    --no-cli-pager

# Tabla 3: la-huella-analytics
create_table_if_not_exists "la-huella-analytics" \
  awslocal dynamodb create-table \
    --table-name la-huella-analytics \
    --attribute-definitions \
      AttributeName=id,AttributeType=S \
      AttributeName=date,AttributeType=S \
    --key-schema \
      AttributeName=id,KeyType=HASH \
      AttributeName=date,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    --no-cli-pager

echo "✅ Tablas DynamoDB creadas correctamente"
create_table_if_not_exists() {
  local table=$1
  shift

  if awslocal dynamodb describe-table --table-name "$table" >/dev/null 2>&1; then
    echo "⚠️  Tabla ya existe: $table (saltando)"
  else
    echo "✅ Creando tabla: $table"

    "$@"

    echo "⏳ Esperando a que la tabla $table exista..."
    awslocal dynamodb wait table-exists --table-name "$table"
    echo "✅ Tabla lista: $table"
  fi
}

# Tabla 1: la-huella-comments
create_table_if_not_exists "la-huella-comments" \
  awslocal dynamodb create-table \
    --table-name la-huella-comments \
    --attribute-definitions \
      AttributeName=id,AttributeType=S \
      AttributeName=productId,AttributeType=S \
      AttributeName=createdAt,AttributeType=S \
    --key-schema \
      AttributeName=id,KeyType=HASH \
    --global-secondary-indexes '[
      {
        "IndexName": "ProductIndex",
        "KeySchema": [
          {"AttributeName":"productId","KeyType":"HASH"},
          {"AttributeName":"createdAt","KeyType":"RANGE"}
        ],
        "Projection": {"ProjectionType":"ALL"}
      }
    ]' \
    --billing-mode PAY_PER_REQUEST \
    --no-cli-pager

# Tabla 2: la-huella-products
create_table_if_not_exists "la-huella-products" \
  awslocal dynamodb create-table \
    --table-name la-huella-products \
    --attribute-definitions \
      AttributeName=id,AttributeType=S \
      AttributeName=category,AttributeType=S \
    --key-schema \
      AttributeName=id,KeyType=HASH \
    --global-secondary-indexes '[
      {
        "IndexName": "CategoryIndex",
        "KeySchema": [
          {"AttributeName":"category","KeyType":"HASH"}
        ],
        "Projection": {"ProjectionType":"ALL"}
      }
    ]' \
    --billing-mode PAY_PER_REQUEST \
    --no-cli-pager

# Tabla 3: la-huella-analytics
create_table_if_not_exists "la-huella-analytics" \
  awslocal dynamodb create-table \
    --table-name la-huella-analytics \
    --attribute-definitions \
      AttributeName=id,AttributeType=S \
      AttributeName=date,AttributeType=S \
    --key-schema \
      AttributeName=id,KeyType=HASH \
      AttributeName=date,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    --no-cli-pager

echo "✅ Tablas DynamoDB creadas correctamente"



echo "=== Creando colas SQS ==="
create_queue_if_not_exists() {
  local queue=$1

  if awslocal sqs get-queue-url --queue-name "$queue" >/dev/null 2>&1; then
    echo "⚠️  Cola ya existe: $queue (saltando)"
  else
    echo "✅ Creando cola: $queue"
    awslocal sqs create-queue --queue-name "$queue" --no-cli-pager
  fi
}

create_queue_if_not_exists "la-huella-processing-queue"
create_queue_if_not_exists "la-huella-notifications-queue"
create_queue_if_not_exists "la-huella-processing-dlq"

echo

echo "=== Creando grupos de logs de CloudWatch ==="
create_log_group_if_not_exists() {
  local group=$1

  if awslocal logs describe-log-groups --log-group-name-prefix "$group" | grep -q "$group"; then
    echo "⚠️  Log group ya existe: $group (saltando)"
  else
    echo "✅ Creando log group: $group"
    awslocal logs create-log-group --log-group-name "$group" --no-cli-pager
  fi
}

create_log_group_if_not_exists "/la-huella/sentiment-analysis"
create_log_group_if_not_exists "/la-huella/api"

echo
echo "=== ✔ Recursos creados correctamente ==="

