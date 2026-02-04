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
    
    echo "unknown"  # Placeholder - reemplazar con lógica real
}

# 🏥 PASO 2: HEALTH CHECK
# =======================
# Esta función debe verificar que un servicio esté funcionando correctamente
check_health() {
    local service=$1
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
    # local max_attempts=5
    # local attempt=1
    # while [ $attempt -le $max_attempts ]; do
    #     if [condición_health]; then
    #         return 0
    #     fi
    #     sleep 2
    #     attempt=$((attempt + 1))
    # done
    
    # Placeholder - implementar lógica real
    sleep 1
    echo -e "${GREEN}✅ Health check completado para $service${NC}"
    return 0
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
        echo -e "${YELLOW}  → Descomentando green-app...${NC}"
    elif [ "$target" = "blue" ]; then
        # TODO: Implementar cambio a Blue
        echo -e "${YELLOW}  → Comentando green-app...${NC}"
        echo -e "${YELLOW}  → Descomentando blue-app...${NC}"
    else
        echo -e "${RED}❌ Target inválido: $target${NC}"
        return 1
    fi
    
    # TODO: Recargar Nginx
    # docker-compose restart nginx
    
    echo -e "${GREEN}✅ Tráfico cambiado a $target${NC}"
}

# 🚀 PASO 4: DESPLEGAR GREEN
# ===========================
# Esta función debe desplegar la nueva versión (Green) sin afectar producción
deploy_green() {
    echo -e "${BLUE}📦 Desplegando versión Green...${NC}"
    
    # TODO: Agregar verificaciones previas
    # - Verificar que Docker Compose esté disponible
    # - Verificar que los archivos necesarios existan
    
    echo -e "${YELLOW}🔨 Construyendo servicios...${NC}"
    # Construir la nueva versión
    docker-compose build green-app
    
    echo -e "${YELLOW}🚀 Levantando servicios...${NC}"
    # Levantar LocalStack y Green (sin afectar Blue)
    docker-compose up -d localstack green-app
    
    echo -e "${YELLOW}⏳ Esperando a que los servicios estén listos...${NC}"
    # Dar tiempo a que los servicios se inicialicen
    sleep 15
    
    # Verificar que Green esté funcionando
    if check_health "green-app"; then
        echo -e "${GREEN}✅ Green desplegado correctamente${NC}"
    else
        echo -e "${RED}❌ Fallo en el despliegue de Green${NC}"
        return 1
    fi
}

# 🔀 PASO 5: SWITCH A PRODUCCIÓN
# ===============================
# Esta función debe cambiar el tráfico de Blue a Green de forma segura
switch_to_green() {
    echo -e "${BLUE}🔄 Cambiando a producción Green...${NC}"
    
    # Cambiar el tráfico
    if switch_traffic "green"; then
        echo -e "${YELLOW}⏳ Verificando que el cambio funcionó...${NC}"
        
        # TODO: Implementar verificación post-cambio
        # - Hacer health check al backend (a través del proxy)
        # - Si falla, hacer rollback automático
        
        if check_health "backend"; then
            echo -e "${GREEN}✅ Cambio a Green completado exitosamente${NC}"
        else
            echo -e "${RED}❌ Verificación falló, ejecutando rollback...${NC}"
            # TODO: Implementar rollback automático
            switch_traffic "blue"
            return 1
        fi
    else
        echo -e "${RED}❌ Fallo en el cambio a Green${NC}"
        return 1
    fi
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
    #
    # EJEMPLO de confirmación:
    # read -p "¿Parar Blue? (y/N): " -n 1 -r
    # if [[ $REPLY =~ ^[Yy]$ ]]; then
    #     docker-compose stop blue-app
    # fi
    
    echo -e "${YELLOW}ℹ️  Blue mantenido para posible rollback${NC}"
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
            ;;
        "green")
            echo -e "${BLUE}🔄 Cambiando de Green a Blue...${NC}"
            # TODO: Llamar a switch_traffic "blue"
            ;;
        *)
            echo -e "${YELLOW}❓ Estado desconocido, cambiando a Green...${NC}"
            # TODO: Llamar a switch_traffic "green"
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
    docker-compose ps
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
