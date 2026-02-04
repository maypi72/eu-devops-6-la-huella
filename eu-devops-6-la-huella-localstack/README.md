# La Huella - análisis de sentimiento

Aplicación Next.js para análisis de sentimiento de comentarios de productos de calzado.

## 🚀 Despliegue Local

### Requisitos
- Node.js 20+ o 22+
- pnpm
- Docker

### Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd eu-devops-6-sentiment
   ```

2. **Instalar dependencias**
   ```bash
   pnpm install
   ```

3. **Ejecutar en desarrollo**
   ```bash
   pnpm dev
   ```
   
   La aplicación estará disponible en `http://localhost:3000`

4. **Build para producción**
   ```bash
   pnpm build
   pnpm start
   ```

## 🧪 Testing

### Ejecutar tests
```bash
# Ejecutar todos los tests
pnpm test

# Verificar linting
pnpm run lint
```


## 🐳 Docker

### Despliegue Simple
```bash
# Construir imagen
docker build -t la-huella-test:latest .

# Ejecutar contenedor
docker run -d \
  --name la-huella-test \
  -p 3000:3000 \
  -e CURRENT_STAGE=2 \
  la-huella-test:latest
```

### Blue-Green Deployment
```bash
# Levantar toda la infraestructura
docker-compose up -d

# Acceder a la aplicación
# http://localhost (versión Blue - estática)

# Desplegar nueva versión (Green)
./deploy-blue-green.sh deploy

# Cambiar tráfico a nueva versión
./deploy-blue-green.sh switch
```

### Health Check
La aplicación incluye un endpoint de health check en `/api/health`

