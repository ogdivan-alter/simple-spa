#!/usr/bin/env bash
#
# Backup de la imagen Docker ogdivan/simple-spa a un .tar (docker save).
# Ancla las rutas a su propia ubicacion: puede ejecutarse desde cualquier carpeta.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<'EOF'
Uso:
  backup.sh VERSION=1.0.0 IMAGE=ogdivan/simple-spa BACKUP_DIR=ruta

Exporta una imagen Docker (docker save) a un archivo .tar en backups.

Argumentos disponibles:
  VERSION=      Version/tag a respaldar (por defecto: docker/version/VERSION.txt)
  IMAGE=        Nombre de la imagen (por defecto: ogdivan/simple-spa)
  BACKUP_DIR=   Carpeta destino del .tar (por defecto: docker/backups)

Ejemplos:
  backup.sh
  backup.sh VERSION=1.0.0
  backup.sh BACKUP_DIR=/mnt/respaldos
EOF
    exit 0
fi

# Valores por defecto
IMAGE="ogdivan/simple-spa"
BACKUP_DIR="$DOCKER_DIR/backups"
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
        VERSION)    VERSION="$value" ;;
        IMAGE)      IMAGE="$value" ;;
        BACKUP_DIR) BACKUP_DIR="$value" ;;
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

# Preparar carpeta y nombre del archivo destino
mkdir -p "$BACKUP_DIR"

IMAGE_FULL="${IMAGE}:${VERSION}"
SAFE_IMAGE="${IMAGE//\//_}"
SAFE_IMAGE="${SAFE_IMAGE//:/_}"
BACKUP_FILE="${BACKUP_DIR}/${SAFE_IMAGE}_${VERSION}.tar"

echo "================================================"
echo "IMAGE:      $IMAGE_FULL"
echo "VERSION:    $VERSION"
echo "BACKUP_DIR: $BACKUP_DIR"
echo "ARCHIVO:    $BACKUP_FILE"
echo "================================================"

# Verificar que la imagen existe localmente
if ! docker image inspect "$IMAGE_FULL" >/dev/null 2>&1; then
    echo "ERROR: La imagen \"$IMAGE_FULL\" no existe localmente." >&2
    echo "       Ejecuta primero el build (build.sh)." >&2
    exit 1
fi

# Exportar la imagen
echo "Exportando imagen..."
if docker save -o "$BACKUP_FILE" "$IMAGE_FULL"; then
    echo "Backup completado: $BACKUP_FILE"
else
    echo "ERROR: Fallo al exportar la imagen." >&2
    exit 1
fi
