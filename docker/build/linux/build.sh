#!/usr/bin/env bash
#
# Build de la imagen Docker ogdivan/simple-spa.
# Ancla las rutas a su propia ubicacion: puede ejecutarse desde cualquier carpeta.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<'EOF'
Uso:
  build.sh PORT=3000 HTTP_PROXY=http://host:puerto HTTPS_PROXY=http://host:puerto NO_PROXY=...

Construye la imagen ogdivan/simple-spa a partir de docker/Dockerfile.
El proxy indicado es el del BUILD (--build-arg); puede diferir del proxy
de runtime, que se pasa con docker run -e.

Argumentos disponibles:
  VERSION=      Version/tag a construir (por defecto: docker/version/VERSION.txt)
  IMAGE=        Nombre de la imagen (por defecto: ogdivan/simple-spa)
  PORT=         Puerto del runtime (por defecto: 3000)
  HTTP_PROXY=   Proxy HTTP para el build
  HTTPS_PROXY=  Proxy HTTPS para el build
  NO_PROXY=     Hosts sin proxy para el build

Ejemplos:
  build.sh
  build.sh PORT=8080
  build.sh HTTP_PROXY=http://10.0.0.1:8080 HTTPS_PROXY=http://10.0.0.1:8080
EOF
    exit 0
fi

# Valores por defecto
IMAGE="ogdivan/simple-spa"
PORT="3000"
HTTP_PROXY=""
HTTPS_PROXY=""
NO_PROXY=""
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
        PORT)        PORT="$value" ;;
        HTTP_PROXY)  HTTP_PROXY="$value" ;;
        HTTPS_PROXY) HTTPS_PROXY="$value" ;;
        NO_PROXY)    NO_PROXY="$value" ;;
        *)
            echo "Parametro desconocido: $arg" >&2
            exit 1
            ;;
    esac
    echo "Procesando argumento: $key = $value"
done

# Leer version (acepta VERSION.txt o version.txt)
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

echo "================================================"
echo "VERSION:     $VERSION"
echo "IMAGE:       $IMAGE:$VERSION"
echo "PORT:        $PORT"
echo "HTTP_PROXY:  $HTTP_PROXY"
echo "HTTPS_PROXY: $HTTPS_PROXY"
echo "NO_PROXY:    $NO_PROXY"
echo "================================================"

# Ejecutar docker build
echo "Ejecutando docker build..."
if docker build \
    --build-arg PORT="$PORT" \
    --build-arg HTTP_PROXY="$HTTP_PROXY" \
    --build-arg HTTPS_PROXY="$HTTPS_PROXY" \
    --build-arg NO_PROXY="$NO_PROXY" \
    -t "$IMAGE:$VERSION" \
    -f "$DOCKER_DIR/Dockerfile" \
    "$ROOT_DIR"; then
    echo "Build completado exitosamente: $IMAGE:$VERSION"
else
    echo "Build fallo." >&2
    exit 1
fi
