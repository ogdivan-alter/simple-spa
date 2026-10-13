#!/usr/bin/env bash
#
# Ejecuta el contenedor de simple-spa.
# Ancla las rutas a su propia ubicacion: puede ejecutarse desde cualquier carpeta.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<'EOF'
Uso:
  run.sh PORT=3000 HTTP_PROXY=http://host:puerto HTTPS_PROXY=http://host:puerto

Ejecuta el contenedor de simple-spa. El proxy indicado es el del RUNTIME
(-e) y puede diferir del proxy de build.

Argumentos disponibles:
  VERSION=      Version/tag a ejecutar (por defecto: docker/version/VERSION.txt)
  IMAGE=        Nombre de la imagen (por defecto: ogdivan/simple-spa)
  NAME=         Nombre del contenedor (por defecto: simple-spa)
  PORT=         Puerto host/contenedor (por defecto: 3000)
  HTTP_PROXY=   Proxy HTTP para el runtime
  HTTPS_PROXY=  Proxy HTTPS para el runtime
  NO_PROXY=     Hosts sin proxy para el runtime
  DETACH=       Y en segundo plano, N en primer plano (por defecto: Y)

Ejemplos:
  run.sh
  run.sh PORT=8080
  run.sh HTTP_PROXY=http://10.0.0.1:8080
EOF
    exit 0
fi

# Valores por defecto
IMAGE="ogdivan/simple-spa"
NAME="simple-spa"
PORT="3000"
HTTP_PROXY=""
HTTPS_PROXY=""
NO_PROXY=""
DETACH="Y"
VERSION=""

# Procesar argumentos CLAVE=valor
for arg in "$@"; do
    if [[ "$arg" != *=* ]]; then
        echo "Parametro desconocido: $arg" >&2
        exit 1
    fi
    key="${arg%%=*}"
    value="${arg#*=}"
    case "$(echo "$key" | tr '[:lower:]' '[:upper:]')" in
        VERSION)     VERSION="$value" ;;
        IMAGE)       IMAGE="$value" ;;
        NAME)        NAME="$value" ;;
        PORT)        PORT="$value" ;;
        HTTP_PROXY)  HTTP_PROXY="$value" ;;
        HTTPS_PROXY) HTTPS_PROXY="$value" ;;
        NO_PROXY)    NO_PROXY="$value" ;;
        DETACH)      DETACH="$value" ;;
        *)
            echo "Parametro desconocido: $arg" >&2
            exit 1
            ;;
    esac
    echo "Procesando argumento: $key = $value"
done

# Leer la version desde VERSION.txt si no se indico
if [[ -z "$VERSION" ]]; then
    VERSION_FILE=""
    for candidate in "$DOCKER_DIR/version/VERSION.txt" "$DOCKER_DIR/version/version.txt"; do
        if [[ -f "$candidate" ]]; then
            VERSION_FILE="$candidate"
            break
        fi
    done
    if [[ -z "$VERSION_FILE" ]]; then
        echo "ERROR: No existe el archivo de version en $DOCKER_DIR/version" >&2
        exit 1
    fi
    VERSION="$(tr -d ' \r\n' < "$VERSION_FILE")"
fi

if [[ -z "$VERSION" ]]; then
    echo "ERROR: La version esta vacia." >&2
    exit 1
fi

# Armar argumentos
RUN_ARGS=(--name "$NAME" -p "${PORT}:${PORT}")
if [[ "$(echo "$DETACH" | tr '[:lower:]' '[:upper:]')" == "Y" ]]; then
    RUN_ARGS+=(-d)
else
    RUN_ARGS+=(-it)
fi

ENV_ARGS=(-e "PORT=${PORT}")
[[ -n "$HTTP_PROXY"  ]] && ENV_ARGS+=(-e "HTTP_PROXY=${HTTP_PROXY}")
[[ -n "$HTTPS_PROXY" ]] && ENV_ARGS+=(-e "HTTPS_PROXY=${HTTPS_PROXY}")
[[ -n "$NO_PROXY"    ]] && ENV_ARGS+=(-e "NO_PROXY=${NO_PROXY}")

echo "================================================"
echo "IMAGE:  $IMAGE:$VERSION"
echo "NAME:   $NAME"
echo "PORT:   $PORT"
echo "================================================"

echo "Ejecutando: docker run ${RUN_ARGS[*]} ${ENV_ARGS[*]} $IMAGE:$VERSION"
if docker run "${RUN_ARGS[@]}" "${ENV_ARGS[@]}" "$IMAGE:$VERSION"; then
    echo "Contenedor iniciado: $NAME"
    echo "Acceso: http://localhost:${PORT}/?quien=ALGUIEN"
else
    echo "ERROR: Fallo al ejecutar el contenedor." >&2
    exit 1
fi
