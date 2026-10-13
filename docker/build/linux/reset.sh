#!/usr/bin/env bash
#
# Elimina la imagen Docker ogdivan/simple-spa y sus contenedores asociados.
# Ancla las rutas a su propia ubicacion: puede ejecutarse desde cualquier carpeta.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<'EOF'
Uso:
  reset.sh VERSION=1.0.0 IMAGE=ogdivan/simple-spa

Elimina la imagen de simple-spa y los contenedores locales que dependen
de ella (docker rm -f + docker rmi).

Argumentos disponibles:
  VERSION=      Version/tag a eliminar (por defecto: docker/version/VERSION.txt)
  IMAGE=        Nombre de la imagen (por defecto: ogdivan/simple-spa)

Ejemplos:
  reset.sh
  reset.sh VERSION=1.0.0
  reset.sh IMAGE=ogdivan/simple-spa
EOF
    exit 0
fi

# Valores por defecto
IMAGE="ogdivan/simple-spa"
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
        VERSION) VERSION="$value" ;;
        IMAGE)   IMAGE="$value" ;;
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

IMAGE_FULL="${IMAGE}:${VERSION}"

echo "================================================"
echo "IMAGE:   $IMAGE_FULL"
echo "================================================"

# Eliminar contenedores creados desde la imagen
echo "Eliminando contenedores asociados..."
found=0
while IFS= read -r cid; do
    [[ -z "$cid" ]] && continue
    echo "  - contenedor $cid"
    docker rm -f "$cid" >/dev/null
    found=1
done < <(docker ps -a -q --filter "ancestor=${IMAGE_FULL}")
if [[ "$found" -eq 0 ]]; then
    echo "  (sin contenedores asociados)"
fi

# Eliminar la imagen
if ! docker image inspect "$IMAGE_FULL" >/dev/null 2>&1; then
    echo "La imagen \"$IMAGE_FULL\" no existe localmente. Nada que eliminar."
    exit 0
fi

echo "Eliminando imagen..."
if docker rmi "$IMAGE_FULL"; then
    echo "Reset completado."
else
    echo "ERROR: Fallo al eliminar la imagen." >&2
    exit 1
fi
