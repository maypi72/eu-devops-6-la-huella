#!/bin/bash

# 🎯 PLANTILLA EDUCATIVA - Blue-Green Deployment
# ===============================================
# 
# OBJETIVO: Implementar un sistema de despliegue Blue-Green que permita:
# 1. Desplegar una nueva versión (Green) sin afectar la producción (Blue)
# 2. Cambiar el tráfico de Blue a Green de forma segura
# 3. Hacer rollback si algo falla
# 4. Limpiar la versión anterior
#
# ARQUITECTURA:
# - Blue App (puerto 3001): Versión actual en producción
# - Green App (puerto 3002): Nueva versión a desplegar
# - Nginx (puerto 80): Proxy que dirige el tráfico
# - LocalStack: Servicios AWS locales (DynamoDB, S3, SQS)

set -e

# 🎨 Colores para output (ya implementado)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
NGINX_CONF="./nginx.conf"

echo -e "${BLUE}🚀 Iniciando Blue-Green Deployment...${NC}"

# 📋 PASO 1: DETECTAR ESTADO ACTUAL
# =================================
# Esta función debe detectar si el tráfico está dirigido a Blue o Green
# analizando el archivo nginx.conf
get_current_target() {
    # TODO: Implementar detección del estado actual
    # PISTA: Usar grep para buscar qué línea está activa en nginx.conf
    # - Si encuentra "server blue-app:3000;" (sin #), está en Blue
    # - Si encuentra "server green-app:3000;" (sin #), está en Green
    # - Devolver "blue", "green" o "unknown"
    if grep -q "server blue-app:3000;" "$NGINX_CONF"; then
        echo "blue"
    elif grep -q "server green-app:3000;" "$NGINX_CONF"; then
        echo "green"
    else
        echo "unknown"  # Placeholder - reemplazar con lógica real
    fi
}

# 🏥 PASO 2: HEALTH CHECK
# =======================
# Esta función debe verificar que un servicio esté funcionando correctamente
check_health() {
    local service=$1
    local url=$2
    echo -e "${YELLOW}🔍 Verificando health de $service...${NC}"
    
    # TODO: Implementar health check real
    # OPCIONES para implementar:
    # 
    # Opción A - Health check directo al contenedor:
    # if docker-compose exec -T $service curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
    #     echo -e "${GREEN}✅ Health check completado para $service${NC}"
    #     return 0
    # fi
    #
    # Opción B - Health check a través del proxy (para backend):
    # if curl -f http://localhost/api/health > /dev/null 2>&1; then
    #     echo -e "${GREEN}✅ Health check completado para $service${NC}"
    #     return 0
    # fi
    #
    # Opción C - Health check con reintentos:
    local max_attempts=5
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if curl -sf "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Health check OK para $service${NC}"
            return 0
        fi
        sleep 3
        attempt=$((attempt + 1))
    done
    
    # Placeholder - implementar lógica real
    sleep 1
    echo -e "${RED}❌ Health check falló para $service${NC}"
    return 1
}

# 🔄 PASO 3: CAMBIAR TRÁFICO
# ===========================
# Esta función debe modificar nginx.conf para dirigir el tráfico a Blue o Green
switch_traffic() {
    local target=$1
    echo -e "${YELLOW}🔄 Cambiando tráfico a $target...${NC}"
    
    # TODO: Implementar el cambio de configuración
    # PASOS NECESARIOS:
    # 1. Modificar nginx.conf para comentar/descomentar las líneas correctas
    # 2. Recargar la configuración de Nginx
    # 3. Verificar que el cambio se aplicó correctamente
    #
    # PISTAS:
    # - Usar sed para modificar nginx.conf:
    #   sed -i.tmp 's/patron_buscar/patron_reemplazar/' nginx.conf
    # - Para cambiar a Green:
    #   - Comentar: server blue-app:3000; → # server blue-app:3000;
    #   - Descomentar: # server green-app:3000; → server green-app:3000;
    # - Para cambiar a Blue: hacer lo contrario
    # - Recargar Nginx: docker-compose restart nginx
    
    if [ "$target" = "green" ]; then
        # TODO: Implementar cambio a Green
        echo -e "${YELLOW}  → Comentando blue-app...${NC}"
        sed -i "s/server blue-app:3000;/# server blue-app:3000;/" "$NGINX_CONF"
        echo -e "${YELLOW}  → Descomentando green-app...${NC}"
        sed -i "s/# server green-app:3000;/server green-app:3000;/" "$NGINX_CONF"
    elif [ "$target" = "blue" ]; then
        # TODO: Implementar cambio a Blue
        echo -e "${YELLOW}  → Comentando green-app...${NC}"
        sed -i "s/server green-app:3000;/# server green-app:3000;/" "$NGINX_CONF"
        echo -e "${YELLOW}  → Descomentando blue-app...${NC}"
        sed -i "s/# server blue-app:3000;/server blue-app:3000;/" "$NGINX_CONF"
    else
        echo -e "${RED}❌ Target inválido: $target${NC}"
        return 1
    fi
    
    # TODO: Recargar Nginx
    # docker-compose restart nginx
    docker compose exec nginx nginx -s reload
    echo -e "${GREEN}✅ Tráfico cambiado a $target${NC}"
}

# 🚀 PASO 4: DESPLEGAR GREEN
# ===========================
# Esta función debe desplegar la nueva versión (Green) sin afectar producción
deploy_green() {
    echo -e "${BLUE}📦 Desplegando versión Green...${NC}"
    echo -e "${BLUE}🔧 Levantando LocalStack + Green...${NC}"

    #Función para verificar si existen las imágenes de localstack y green-app
    image_exists() {
        local image_name=$1
        if docker image inspect "$image_name" > /dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    }

    # TODO: Agregar verificaciones previas
    # - Verificar que Docker Compose esté disponible
    if docker compose version >/dev/null 2>&1; then
        echo "✅ Docker Compose OK"
    else
        echo "❌ Docker Compose no disponible"
        return 1
    fi

    # - Verificar que los archivos necesarios existan
    # Verificar existe fichero docker-compose.yml
    LOCALSTACK_COMPOSE_FILE="./docker-compose.yml"
    if [ ! -f "$LOCALSTACK_COMPOSE_FILE" ]; then
    echo -e "${RED}❌ No se encuentra $LOCALSTACK_COMPOSE_FILE${NC}"
    retrun 1
    fi
    #Comprobamos existencia de scripts de inicialización AWS
    INIT_DIR="./scripts"
    for script in "01-create-resources.sh" "02-insert-data.sh"; do
        if [ ! -f "$INIT_DIR/$script" ]; then
            echo -e "${RED}❌ No se encuentra $INIT_DIR/$script${NC}"
            exit 1
        fi
    done
    echo -e "${GREEN}✅ Todos los archivos imprescindibles existen${NC}"


    #VERIFICAR EXISTENCIA IMÁGENES LOCALSTACK Y GREEN APP
    #Imágenes de los contenedores
    GREEN_IMAGE="la-huella-green-app:latest"   # Ajusta según tu docker-compose.yml
    LOCALSTACK_IMAGE="localstack/localstack:latest"


    if image_exists "$GREEN_IMAGE"; then
        echo -e "${YELLOW}ℹ️ Imagen $GREEN_IMAGE ya existe, no se construye.${NC}"
    else
        echo -e "${BLUE}🛠 Construyendo imagen $GREEN_IMAGE...${NC}"
        docker compose --profile green build green-app
    fi

    # LocalStack 
    if image_exists "$LOCALSTACK_IMAGE"; then
        echo -e "${YELLOW}ℹ️ Imagen $LOCALSTACK_IMAGE ya existe, no se construye.${NC}"
    else
        echo -e "${BLUE}🛠 Construyendo imagen $LOCALSTACK_IMAGE...${NC}"
        docker compose --profile green build localstack
    fi

    #- Levantar localstack y green app
    echo -e "${BLUE}🔧 Levantando LocalStack + Green...${NC}"
    docker compose --profile green up -d localstack green-app

    #-ESPERAR A QUE LOCALSTACK ESTÉ DISPONIBLE
    echo -e "${BLUE}⏳ Esperando a que LocalStack responda...${NC}"
    check_health "localstack" "http://localhost:4566/health"
    
    #-Inicializar recursos aws
    echo -e "${BLUE}⚙️ Inicializando recursos en LocalStack...${NC}"
    bash "$INIT_DIR/01-create-resources.sh"
    bash "$INIT_DIR/02-insert-data.sh" 

    sleep 15

    #-Esperar a que Green App esté lista ---
    echo -e "${BLUE}⏳ Esperando a que Green App responda...${NC}"
    if check_health "green-app" "http://localhost:3002/api/health";then
       echo -e "${GREEN}✅ Green desplegado correctamente${NC}"
    else
       echo -e "${RED}❌ Fallo en el despliegue de Green${NC}"
       return 1
    fi   
}

# 🔀 PASO 5: SWITCH A PRODUCCIÓN
# ===============================
# Esta función debe cambiar el tráfico de Blue a Green de forma segura
     # TODO: Implementar verificación post-cambio
     #- Hacer health check al backend (a través del proxy)
     # - Si falla, hacer rollback automático
switch_to_green() {
    echo -e "${BLUE}🔄 Cambiando a producción Green...${NC}"
    
    # Cambiar el tráfico
    switch_traffic "green"
    if ! check_health "green-app" "http://localhost/api/health"; then
        echo -e "${RED}❌ Health check falló, rollback a Blue${NC}"
        switch_traffic "blue"
        return 1
    fi
     echo -e "${GREEN}✅ Tráfico cambiado a Green con éxito${NC}"
}

# 🧹 PASO 6: CLEANUP
# ===================
# Esta función debe limpiar la versión anterior (opcional)
cleanup_blue() {
    echo -e "${BLUE}🧹 Limpiando versión Blue...${NC}"
    
    # TODO: Implementar cleanup inteligente
    # OPCIONES:
    # 1. Preguntar al usuario si quiere parar Blue
     # 2. Mantener Blue corriendo para posible rollback
    # 3. Parar Blue automáticamente después de X tiempo
     if docker compose ps blue-app | grep -q "Up"; then
        read -p "¿Deseas parar la versión Blue para liberar recursos? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}⏳ Parando Blue...${NC}"
            docker compose stop blue-app
            echo -e "${GREEN}✅ Blue detenido${NC}"
        else
            echo -e "${YELLOW}ℹ️ Blue mantenido para posible rollback${NC}"
        fi
    else
        echo -e "${YELLOW}ℹ️ Blue no está corriendo, no se hace nada${NC}"
    fi

    echo -e "${GREEN}✅ Cleanup completado${NC}"
}

# 🔄 PASO 7: SWITCH INTELIGENTE (BONUS)
# ======================================
# Esta función debe alternar automáticamente entre Blue y Green
intelligent_switch() {
    local current_target=$(get_current_target)
    
    echo -e "${BLUE}🔍 Estado actual detectado: $current_target${NC}"
    
    # TODO: Implementar switch inteligente
    # - Si está en Blue → cambiar a Green
    # - Si está en Green → cambiar a Blue
    # - Si es unknown → cambiar a Green por defecto
    
    case $current_target in
        "blue")
            echo -e "${BLUE}🔄 Cambiando de Blue a Green...${NC}"
            # TODO: Llamar a switch_traffic "green"
            switch_traffic "green"
            ;;
        "green")
            echo -e "${BLUE}🔄 Cambiando de Green a Blue...${NC}"
            # TODO: Llamar a switch_traffic "blue"
            switch_traffic "blue"
            ;;
        *)
            echo -e "${YELLOW}❓ Estado desconocido, cambiando a Green...${NC}"
            # TODO: Llamar a switch_traffic "green"
            switch_traffic "green"
            ;;
    esac
}

# 📊 PASO 8: MOSTRAR ESTADO (BONUS)
# ==================================
show_status() {
    echo -e "${BLUE}📊 Estado actual del sistema:${NC}"
    echo
    
    # Mostrar servicios corriendo
    echo -e "${YELLOW}Servicios:${NC}"
    docker compose ps
    echo
    
    # Mostrar configuración actual
    echo -e "${YELLOW}Configuración de tráfico:${NC}"
    local current_target=$(get_current_target)
    case $current_target in
        "blue")
            echo -e "${BLUE}➡️  Tráfico dirigido a: BLUE${NC}"
            ;;
        "green")
            echo -e "${GREEN}➡️  Tráfico dirigido a: GREEN${NC}"
            ;;
        *)
            echo -e "${RED}❓ Configuración no reconocida${NC}"
            ;;
    esac
}

# 🎯 EJECUCIÓN PRINCIPAL
# =======================
case "${1:-help}" in
    "deploy")
        echo -e "${BLUE}📦 Modo: Solo desplegar Green${NC}"
        deploy_green
        ;;
    "switch")
        echo -e "${BLUE}🔄 Modo: Solo cambiar a Green${NC}"
        switch_to_green
        ;;
    "cleanup")
        echo -e "${BLUE}🧹 Modo: Solo cleanup${NC}"
        cleanup_blue
        ;;
    "full")
        echo -e "${BLUE}🚀 Modo: Despliegue completo${NC}"
        deploy_green
        switch_to_green
        cleanup_blue
        ;;
    "intelligent")
        echo -e "${BLUE}🤖 Modo: Switch inteligente${NC}"
        intelligent_switch
        ;;
    "status")
        show_status
        ;;
    "help"|"")
        echo -e "${BLUE}Blue-Green Deployment Script - Plantilla Educativa${NC}"
        echo
        echo "Uso: $0 {comando}"
        echo
        echo "Comandos disponibles:"
        echo "  deploy      - Solo desplegar Green"
        echo "  switch      - Solo cambiar tráfico a Green"
        echo "  cleanup     - Solo limpiar Blue"
        echo "  full        - Despliegue completo (deploy + switch + cleanup)"
        echo "  intelligent - Switch inteligente (alterna entre Blue/Green)"
        echo "  status      - Mostrar estado actual"
        echo "  help        - Mostrar esta ayuda"
        echo
        echo "Ejemplos:"
        echo "  $0 deploy          # Solo desplegar nueva versión"
        echo "  $0 full            # Proceso completo"
        echo "  $0 intelligent     # Alternar automáticamente"
        ;;
    *)
        echo -e "${RED}❌ Comando no reconocido: $1${NC}"
        echo "Usa '$0 help' para ver los comandos disponibles"
        exit 1
        ;;
esac

if [ $? -eq 0 ]; then
    echo -e "${GREEN}🎉 Operación completada exitosamente!${NC}"
else
    echo -e "${RED}❌ Operación falló${NC}"
    exit 1
fi
