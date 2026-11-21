#!/bin/bash
# Verifica che tutti i pacchetti elencati esistano nei repository di trixie.
set -euo pipefail

cd "$(dirname "$0")/.."

LIST="$(grep -hv '^[[:space:]]*#' config/package-lists/*.list.chroot \
	| tr -d '\r' | sed 's/[[:space:]]//g' | sed '/^$/d' | sort -u)"

INDEX=/tmp/peach-packages.txt
if [ ! -s "${INDEX}" ]; then
	echo "==> scarico gli indici trixie"
	for area in main contrib non-free non-free-firmware; do
		curl -fsSL "https://deb.debian.org/debian/dists/trixie/${area}/binary-amd64/Packages.xz" \
			| xz -dc | awk '/^Package: /{print $2}'
	done | sort -u > "${INDEX}"
fi

MISSING=0
while IFS= read -r pkg; do
	if ! grep -qxF "${pkg}" "${INDEX}"; then
		echo "MANCANTE: ${pkg}"
		MISSING=1
	fi
done <<< "${LIST}"

if [ "${MISSING}" -ne 0 ]; then
	echo "Errore: alcuni pacchetti non esistono in trixie." >&2
	exit 1
fi

echo "OK: $(echo "${LIST}" | wc -l) pacchetti validi."
