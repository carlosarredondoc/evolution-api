#!/bin/bash
# entrypoint.sh

# Salir inmediatamente si un comando falla
set -e

echo "[INFO] Desplegando migraciones de la base de datos..."
npm run db:deploy

echo "[INFO] Migraciones completadas."

# "exec $@" ejecuta el comando pasado al contenedor (el CMD del Dockerfile)
# En este caso, ejecutará "npm run start:prod"
exec "$@"
