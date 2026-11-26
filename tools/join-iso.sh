#!/bin/bash
# Peach OS -- ricompone le ISO scaricate da GitHub Releases.
# Uso: ./tools/join-iso.sh amd64
set -euo pipefail
cd "$(dirname "$0")/.."

ARCH="${1:-amd64}"
OUT="PeachOS-1.0-${ARCH}.iso"
PARTS=(release-assets/PeachOS-1.0-${ARCH}.iso.part*)
if [ ! -e "${PARTS[0]}" ]; then
	echo "Nessuna parte trovata per ${ARCH} in release-assets/." >&2
	exit 1
fi

echo "==> ricompongo ${OUT}"
cat "${PARTS[@]}" > "$OUT"
echo "==> verifica checksum"
if [ -f "release-assets/PeachOS-1.0-${ARCH}.iso.sha256" ]; then
	( cd release-assets && sed "s|  .*|  ../${OUT}|" "PeachOS-1.0-${ARCH}.iso.sha256" ) | sha256sum -c -
else
	sha256sum "$OUT"
fi
