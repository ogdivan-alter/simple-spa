#!/usr/bin/env bash
#
# Bump de la version en docker/version/VERSION.txt (fuente unica del proyecto).
# Ancla las rutas a su propia ubicacion: puede ejecutarse desde cualquier carpeta.
#
# No hace commit: prepara el cambio para la rama release/<version> y su PR.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERSION_FILE="$DOCKER_DIR/version/VERSION.txt"

usage() {
    cat <<'EOF'
Uso:
  bump.sh major|minor|patch     Incrementa la parte indicada (semver).
  bump.sh VERSION=x.y.z         Fija una version explicita.
  bump.sh                       Muestra la version actual.

Actualiza la fuente unica docker/version/VERSION.txt (no hace commit).

Ejemplos:
  bump.sh patch        # 1.0.0 -> 1.0.1
  bump.sh minor        # 1.0.0 -> 1.1.0
  bump.sh major        # 1.0.0 -> 2.0.0
  bump.sh VERSION=2.1.0
EOF
}

current=""
if [[ -f "$VERSION_FILE" ]]; then
    current="$(tr -d ' \r\n' < "$VERSION_FILE")"
fi

if [[ $# -eq 0 || "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    echo
    echo "Version actual: ${current:-<vacia>}"
    exit 0
fi

if [[ ! "$current" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: version actual no valida en $VERSION_FILE: '$current'" >&2
    echo "       se espera el formato X.Y.Z" >&2
    exit 1
fi

IFS='.' read -r major minor patch <<< "$current"

arg="$1"
new=""
case "$(echo "$arg" | tr '[:lower:]' '[:upper:]')" in
    MAJOR)  new="$((major + 1)).0.0" ;;
    MINOR)  new="$major.$((minor + 1)).0" ;;
    PATCH)  new="$major.$minor.$((patch + 1))" ;;
    VERSION=*)
        new="${arg#*=}"
        if [[ ! "$new" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "ERROR: VERSION debe ser semver X.Y.Z (recibido: '$new')" >&2
            exit 1
        fi
        ;;
    *)
        echo "ERROR: argumento no reconocido: '$arg'" >&2
        echo >&2
        usage >&2
        exit 1
        ;;
esac

printf '%s\n' "$new" > "$VERSION_FILE"

echo "================================================"
echo "VERSION anterior: $current"
echo "VERSION nueva:    $new"
echo "Archivo:          $VERSION_FILE"
echo "================================================"
echo "Siguiente paso: crear la rama release/$new y abrir el PR."
