#!/bin/sh
# Instala o actualiza onasor-mc (launcher de Minecraft para la terminal) en Linux desde
# las descargas públicas de github.com/GonzaloRosano/onasor.
#
#   curl -fsSL https://raw.githubusercontent.com/GonzaloRosano/onasor/main/mc.sh | sh
#
# Opciones por variable de entorno:
#   VERSION=v0.1.0   una versión puntual (por defecto, la última)
#   DIR=/opt/bin     dónde instalarlo (por defecto /usr/local/bin, o ~/.local/bin sin sudo)
set -eu

REPO="GonzaloRosano/onasor"
TOOL="onasor-mc"
PREFIX="mc-v"

fail() { printf '\033[31mx %s\033[0m\n' "$1" >&2; exit 1; }
step() { printf '> %s\n' "$1"; }

command -v curl >/dev/null 2>&1 || fail "hace falta curl"
if command -v sha256sum >/dev/null 2>&1; then SHA="sha256sum"
elif command -v shasum >/dev/null 2>&1; then SHA="shasum -a 256"
else fail "hace falta sha256sum"; fi

os=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$(uname -m)" in
  x86_64|amd64) arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) fail "arquitectura no soportada: $(uname -m)" ;;
esac
case "$os" in
  linux) ;;
  darwin) [ "$arch" = arm64 ] || fail "en macOS solo hay binario para Apple Silicon" ;;
  *) fail "sistema no soportado: $os (en Windows usá mc.ps1)" ;;
esac
asset="$TOOL-$os-$arch"

# 1. Release: el último de esta herramienta, o el pedido
if [ -n "${VERSION:-}" ]; then
  tag="$PREFIX${VERSION#v}"
else
  tag=$(curl -fsSL -H "Accept: application/vnd.github+json" "https://api.github.com/repos/$REPO/releases?per_page=100" \
    | grep -o "\"tag_name\": *\"$PREFIX[^\"]*\"" | head -n 1 | sed 's/.*"\([^"]*\)"$/\1/') || true
  [ -n "$tag" ] || fail "no encontré un release de $TOOL"
fi
base="https://github.com/$REPO/releases/download/$tag"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
step "descargando $TOOL ${tag#mc-}..."
curl -fsSL -o "$tmp/$asset" "$base/$asset" || fail "no pude descargar $asset de $tag"
curl -fsSL -o "$tmp/SHA256SUMS" "$base/SHA256SUMS" || fail "no pude descargar SHA256SUMS"

# 2. Verificar el SHA-256 contra SHA256SUMS del mismo release
expected=$(grep " \*\?$asset\$" "$tmp/SHA256SUMS" | head -n 1 | cut -d' ' -f1)
actual=$(cd "$tmp" && $SHA "$asset" | cut -d' ' -f1)
[ -n "$expected" ] && [ "$expected" = "$actual" ] || fail "el SHA-256 no coincide: descarga corrupta o alterada"
chmod 755 "$tmp/$asset"

# 3. Instalar: /usr/local/bin (con sudo si hace falta) o ~/.local/bin
SUDO=""
if [ -z "${DIR:-}" ]; then
  DIR=/usr/local/bin
  if [ ! -w "$DIR" ]; then
    if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
      SUDO="sudo"
    else
      DIR="$HOME/.local/bin"
    fi
  fi
elif [ ! -w "$DIR" ] && [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi
$SUDO mkdir -p "$DIR"
$SUDO install -m 755 "$tmp/$asset" "$DIR/$TOOL" || fail "no pude instalar en $DIR"

case ":$PATH:" in
  *":$DIR:"*) ;;
  *) printf '> %s no está en el PATH: agregalo a ~/.profile (export PATH="%s:$PATH")\n' "$DIR" "$DIR" ;;
esac
printf '\033[32mv %s instalado en %s\033[0m\n' "$("$DIR/$TOOL" version)" "$DIR/$TOOL"
echo "  para actualizar: $TOOL update (o volvé a correr el mismo comando)"
