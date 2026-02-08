#!/bin/bash
set -e

echo "🌱 Insertando datos de ejemplo en LocalStack..."

# Variables de entorno
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"
export AWS_DEFAULT_REGION="eu-west-1"

REGION="eu-west-1"
ENDPOINT="http://localhost:4566"

# Función de check
check_command() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ Error en: $1"
        exit 1
    fi
}

# Esperar a que las tablas existan
#for table in la-huella-products la-huella-comments; do
 #   echo "⏳ Esperando a que la tabla $table exista..."
  #  aws --endpoint-url="$ENDPOINT" dynamodb wait table-exists --table-name "$table"
   # check_command "Tabla $table lista"
#done

# Productos de ejemplo
echo "📦 Insertando productos de ejemplo..."

aws --endpoint-url="$ENDPOINT" dynamodb put-item \
    --table-name la-huella-products \
    --item '{"id":{"S":"prod-001"},"name":{"S":"Zapatillas Running Pro"},"category":{"S":"running"},"price":{"N":"89.99"},"description":{"S":"Zapatillas profesionales para running con tecnología de amortiguación avanzada"},"imageUrl":{"S":"https://example.com/running-pro.jpg"},"createdAt":{"S":"2024-01-15T10:00:00Z"}}'
check_command "Producto prod-001 insertado"

aws --endpoint-url="$ENDPOINT" dynamodb put-item \
    --table-name la-huella-products \
    --item '{"id":{"S":"prod-002"},"name":{"S":"Botas Montaña Explorer"},"category":{"S":"hiking"},"price":{"N":"129.99"},"description":{"S":"Botas resistentes para montaña con membrana impermeable"},"imageUrl":{"S":"https://example.com/hiking-explorer.jpg"},"createdAt":{"S":"2024-01-16T11:00:00Z"}}'
check_command "Producto prod-002 insertado"

aws --endpoint-url="$ENDPOINT" dynamodb put-item \
    --table-name la-huella-products \
    --item '{"id":{"S":"prod-003"},"name":{"S":"Sandalias Verano Comfort"},"category":{"S":"casual"},"price":{"N":"45.99"},"description":{"S":"Sandalias cómodas para el verano con suela ergonómica"},"imageUrl":{"S":"https://example.com/summer-comfort.jpg"},"createdAt":{"S":"2024-01-17T12:00:00Z"}}'
check_command "Producto prod-003 insertado"

# Comentarios de ejemplo
echo "💬 Insertando comentarios de ejemplo..."

aws --endpoint-url="$ENDPOINT" dynamodb put-item \
    --table-name la-huella-comments \
    --item '{"id":{"S":"comment-001"},"productId":{"S":"prod-001"},"userId":{"S":"user-001"},"userName":{"S":"María García"},"comment":{"S":"Excelentes zapatillas, muy cómodas para correr largas distancias. Las recomiendo totalmente."},"sentiment":{"S":"positive"},"sentimentScore":{"N":"0.89"},"rating":{"N":"5"},"createdAt":{"S":"2024-01-20T14:30:00Z"},"processed":{"BOOL":true}}'
check_command "Comentario comment-001 insertado"

aws --endpoint-url="$ENDPOINT" dynamodb put-item \
    --table-name la-huella-comments \
    --item '{"id":{"S":"comment-002"},"productId":{"S":"prod-001"},"userId":{"S":"user-002"},"userName":{"S":"Carlos Ruiz"},"comment":{"S":"El producto llegó defectuoso, la suela se despegó después de una semana. Muy decepcionado."},"sentiment":{"S":"negative"},"sentimentScore":{"N":"0.12"},"rating":{"N":"1"},"createdAt":{"S":"2024-01-21T09:15:00Z"},"processed":{"BOOL":true}}'
check_command "Comentario comment-002 insertado"

aws --endpoint-url="$ENDPOINT" dynamodb put-item \
    --table-name la-huella-comments \
    --item '{"id":{"S":"comment-003"},"productId":{"S":"prod-002"},"userId":{"S":"user-003"},"userName":{"S":"Ana López"},"comment":{"S":"Las botas están bien, cumplen su función pero esperaba mejor calidad por el precio."},"sentiment":{"S":"neutral"},"sentimentScore":{"N":"0.55"},"rating":{"N":"3"},"createdAt":{"S":"2024-01-22T16:45:00Z"},"processed":{"BOOL":true}}'
check_command "Comentario comment-003 insertado"

echo "🎉 ¡Datos de ejemplo insertados correctamente!"
