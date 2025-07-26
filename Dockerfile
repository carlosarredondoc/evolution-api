# --- ETAPA 1: Builder (Construcción) ---
# Usamos la imagen específica de Node.js que tu script requiere
FROM node:20.10.0-alpine AS builder

# Instalamos dependencias necesarias para la compilación
RUN apk add --no-cache git python3 make g++

WORKDIR /app

# Copiamos package.json primero para aprovechar el caché de Docker
COPY package.json package-lock.json* ./
RUN npm install

# Copiamos el resto del código fuente
COPY . .

# Generamos el cliente de Prisma (no necesita conexión a la BD)
RUN npm run db:generate

# Construimos la aplicación para producción
RUN npm run build


# --- ETAPA 2: Final (Producción) ---
# Usamos la misma imagen base para mantener la consistencia
FROM node:20.10.0-alpine

WORKDIR /app

# Creamos un usuario no-root para ejecutar la aplicación por seguridad
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Copiamos solo los artefactos necesarios desde la etapa de construcción
COPY --from=builder /app/package.json .
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
# Copiamos nuestro script de arranque (lo crearemos en el siguiente paso)
COPY --chown=appuser:appgroup entrypoint.sh .
RUN chmod +x ./entrypoint.sh

# Exponemos el puerto que usará la aplicación
EXPOSE 8080

# El ENTRYPOINT ejecutará nuestro script de arranque
ENTRYPOINT [ "./entrypoint.sh" ]

# El CMD es el comando por defecto que recibirá el entrypoint
CMD [ "npm", "run", "start:prod" ]
