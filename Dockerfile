# Etapa 1: Construcción
FROM node:20-alpine AS builder
WORKDIR /app

# Instalar pnpm
RUN npm install -g pnpm

# Copiar dependencias
COPY package.json pnpm-lock.yaml ./

# Instalar dependencias
RUN pnpm install --frozen-lockfile

# Copiar código
COPY . .

# Build en modo standalone
RUN pnpm build

# Etapa 2: Imagen final
FROM node:20-alpine AS runner

# Crear usuario no root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copiar solo lo necesario para standalone
COPY --from=builder /app/.next/standalone ./
#COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/static ./.next/static

# Cambiar a usuario seguro
USER appuser

# Exponer puerto 3000 (Next standalone)
EXPOSE 3000

# Ejecutar servidor standalone (correcto para Next.js 15)
CMD ["node", "server.js"]

LABEL name="la-huella-test"