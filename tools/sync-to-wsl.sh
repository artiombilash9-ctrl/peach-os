#!/bin/bash
#
# Sincronizza il progetto Peach OS dentro l'ambiente di build Debian.
#
#   bash tools/sync-to-wsl.sh "C:\percorso\peach-os" [/srv/peach-build/build/peach-os]
#
set -euo pipefail

if [ "$#" -lt 1 ]; then
	echo "Uso: $0 <percorso-windows-del-progetto> [destinazione]" >&2
	exit 1
fi

SRC="$(wslpath -a "$1")"
TARGET="${2:-/srv/peach-build/build/peach-os}"

if [ ! -d "${SRC}" ]; then
	echo "Errore: ${SRC} non esiste." >&2
	exit 1
fi

mkdir -p "$(dirname "${TARGET}")"
rm -rf "${TARGET}"
cp -a "${SRC}" "${TARGET}"

# Il filesystem Windows non conserva i permessi: li normalizziamo.
find "${TARGET}" -type d -exec chmod 755 {} +
find "${TARGET}" -type f -exec chmod 644 {} +
chmod 755 "${TARGET}/auto/config" \
	"${TARGET}/build.sh" "${TARGET}"/tools/*.sh \
	"${TARGET}"/config/hooks/normal/*.hook.* \
	"${TARGET}"/config/includes.chroot/usr/local/bin/* 2>/dev/null || true

echo "==> Progetto sincronizzato in ${TARGET}"
