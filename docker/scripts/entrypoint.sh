#!/usr/bin/env bash
#
# Entry point de la imagen simple-spa.
# Sirve los archivos de /app con el servidor HTTP de Python.
#
# - PORT: debe coincidir con el default del Dockerfile (3000).
# - Proxy de runtime: el proceso lo toma de las variables inyectadas con
#   `docker run -e` (pueden diferir de las del build). No se reescribe
#   configuracion de apt aqui.
#
set -euo pipefail

PORT="${PORT:-3000}"

echo "simple-spa disponible en http://0.0.0.0:${PORT}/?quien=ALGUIEN"

exec python3 -m http.server "${PORT}" --directory /app
