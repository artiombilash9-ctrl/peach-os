#!/bin/bash
#
# Copia la ISO prodotta dal chroot nella cartella dist/ del progetto.
#
#   bash tools/collect-iso.sh "C:\percorso\peach-os\dist"
#
set -euo pipefail

if [ "$#" -lt 1 ]; then
	echo "Uso: $0 <cartella-di-destinazione>" >&2
	exit 1
fi

SRC="${SRC:-/srv/peach-build/build/peach-os/dist}"
DEST="$(wslpath -a "$1")"

if [ ! -f "${SRC}/PeachOS-1.0-amd64.iso" ]; then
	echo "Errore: ISO non trovata in ${SRC}." >&2
	exit 1
fi

mkdir -p "${DEST}"
cp -f "${SRC}/PeachOS-1.0-amd64.iso" "${DEST}/"
cp -f "${SRC}/PeachOS-1.0-amd64.iso.sha256" "${DEST}/" 2>/dev/null || true

echo "==> ISO copiata in ${DEST}"
ls -lh "${DEST}/PeachOS-1.0-amd64.iso"
