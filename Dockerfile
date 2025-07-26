# STAGE 1: Builder
FROM node:20-alpine AS builder

# Declara las variables que se necesitan durante el build
ARG DATABASE_PROVIDER
ARG DATABASE_CONNECTION_URI

# Hazlas disponibles como variables de entorno para los comandos RUN
ENV DATABASE_PROVIDER=${DATABASE_PROVIDER}
ENV DATABASE_CONNECTION_URI=${DATABASE_CONNECTION_URI}

RUN apk update && \
    apk add --no-cache git ffmpeg wget curl bash openssl

WORKDIR /evolution

COPY ./package.json ./tsconfig.json ./
RUN npm install --force

COPY . .

# Corrige los permisos y formato de los scripts
RUN chmod +x ./docker/scripts/* && dos2unix ./docker/scripts/*

# Este script SÍ se ejecuta en el build, porque no necesita conexión a la BD
RUN ./docker/scripts/generate_database.sh

# Compila la aplicación
RUN npm run build


# STAGE 2: Final Image
FROM node:20-alpine AS final

RUN apk update && \
    apk add tzdata ffmpeg bash openssl

WORKDIR /evolution

# Copia solo lo necesario desde el builder
COPY --from=builder /evolution/package.json ./package.json
COPY --from=builder /evolution/package-lock.json ./package-lock.json
COPY --from=builder /evolution/node_modules ./node_modules
COPY --from=builder /evolution/dist ./dist
COPY --from=builder /evolution/prisma ./prisma
COPY --from=builder /evolution/manager ./manager
COPY --from=builder /evolution/public ./public
COPY --from=builder /evolution/docker ./docker
COPY --from=builder /evolution/runWithProvider.js ./runWithProvider.js

ENV TZ=America/Sao_Paulo
ENV DOCKER_ENV=true

EXPOSE 8080

# Este es el comando final. Ejecuta las migraciones y LUEGO inicia la app.
ENTRYPOINT ["/bin/bash", "-c", ". ./docker/scripts/deploy_database.sh && npm run start:prod" ]
