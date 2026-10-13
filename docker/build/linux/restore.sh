#!/usr/bin/env bash
#
# Restore de la imagen Docker ogdivan/simple-spa desde un .tar (docker load).
# Ancla las rutas a su propia ubicacion: puede ejecutarse desde cualquier carpeta.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<'EOF'
Uso:
  restore.sh VERSION=1.0.0 IMAGE=ogdivan/simple-spa BACKUP_DIR=ruta
  restore.sh FILE=ruta/ogdivan_simple-spa_1.0.0.tar

Reimporta una imagen Docker (docker load) desde un .tar de backups.

Argumentos disponibles:
  FILE=         Ruta directa al .tar (tiene prioridad sobre lo demas)
  VERSION=      Version/tag (por defecto: docker/version/VERSION.txt)
  IMAGE=        Nombre de la imagen (por defecto: ogdivan/simple-spa)
  BACKUP_DIR=   Carpeta de los .tar (por defecto: docker/backups)

Ejemplos:
  restore.sh
  restore.sh VERSION=1.0.0
  restore.sh FILE=backups/ogdivan_simple-spa_1.0.0.tar
EOF
    exit 0
fi

# Valores por defecto
IMAGE="ogdivan/simple-spa"
BACKUP_DIR="$DOCKER_DIR/backups"
FILE=""
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
        FILE)       FILE="$value" ;;
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

# Deducir el archivo .tar si no se indico FILE
if [[ -z "$FILE" ]]; then
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
    SAFE_IMAGE="${IMAGE//\//_}"
    SAFE_IMAGE="${SAFE_IMAGE//:/_}"
    FILE="${BACKUP_DIR}/${SAFE_IMAGE}_${VERSION}.tar"
fi

echo "================================================"
echo "ARCHIVO: $FILE"
echo "================================================"

if [[ ! -f "$FILE" ]]; then
    echo "ERROR: No existe el archivo de backup: $FILE" >&2
    echo "       Ejecuta primero el backup (backup.sh)." >&2
    exit 1
fi

# Importar la imagen
echo "Importando imagen..."
if docker load -i "$FILE"; then
    echo "Restore completado."
else
    echo "ERROR: Fallo al importar la imagen." >&2
    exit 1
fi
