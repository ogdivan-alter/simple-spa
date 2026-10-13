# syntax=docker/dockerfile:1
# ============================================================
# simple-spa - SPA estatica servida con Python http.server
# Imagen base: ogdivan/appmin-py (Python + utilidades minimas).
#
# Patron build -> runtime:
#   BUILD:   proxy propio del build (ARG). No persiste en la imagen final.
#   RUNTIME: puerto parametrizable (PORT/EXPOSE). El proxy del runtime se
#            inyecta con `docker run -e` y puede tener valores distintos
#            a los del build.
#
# El valor por defecto de PORT en el Dockerfile DEBE coincidir con el de
# docker/scripts/entrypoint.sh.
# ============================================================

# ================================
# Stage 1: build
# ================================
FROM ogdivan/appmin-py:1.0.0 AS build

# Proxy SOLO del build. Docker predefine estos ARG y no se guardan en la
# imagen final. Se pasan con:
#   docker build --build-arg HTTP_PROXY=... --build-arg HTTPS_PROXY=... --build-arg NO_PROXY=...
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

WORKDIR /app

# Solo el contenido de la SPA (el .dockerignore filtra el resto).
COPY src/ /app/

# (Si el build requiriera red -apt/pip-, aqui se usaria el proxy de build.)

# ================================
# Stage 2: runtime
# ================================
FROM ogdivan/appmin-py:1.0.0 AS runtime

LABEL org.opencontainers.image.title="simple-spa" \
      org.opencontainers.image.description="SPA estatica (index.html) servida con python http.server" \
      org.opencontainers.image.licenses="MIT"

# --- Puerto: exclusivo del runtime y parametrizable ---
# Cambiable en build con: --build-arg PORT=xxxx
ARG PORT=3000
ENV PORT=${PORT} \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY --from=build /app /app

# Entrypoint + usuario sin privilegios en una sola capa.
COPY docker/scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
 && useradd --uid 10001 --no-create-home appuser \
 && chown -R appuser:appuser /app
USER appuser

# EXPOSE expande PORT: unica fuente de verdad, alineada con entrypoint.sh.
EXPOSE ${PORT}

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python3 -c "import os,urllib.request,sys; \
url='http://127.0.0.1:'+os.environ.get('PORT','3000')+'/'; \
sys.exit(0 if urllib.request.urlopen(url, timeout=2).status==200 else 1)"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
