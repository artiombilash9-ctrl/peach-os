#!/bin/bash
#
# Sincronizza il progetto Peach OS dentro l'ambiente di build Debian.
#
#   bash tools/sync-to-wsl.sh "C:\percorso\peach-os" [/srv/peach-build/build/peach-os]
#
# Copia solo i file sorgente: le directory generate da live-build
# (chroot/, binary/, cache/, .build/) restano intatte, cosi' la build
# successiva e' incrementale e non riparte da debootstrap.
#
set -euo pipefail

if [ "$#" -lt 1 ]; then
	echo "Uso: $0 <percorso-windows-del-progetto> [destinazione]" >&2
	exit 1
fi

case "$1" in
	/*) SRC="$1" ;;
	*) SRC="$(wslpath -a "$1")" ;;
esac
TARGET="${2:-/srv/peach-build/build/peach-os}"

if [ ! -d "${SRC}" ]; then
	echo "Errore: ${SRC} non esiste." >&2
	exit 1
fi

mkdir -p "${TARGET}"

# Rimuove solo cio' che proviene dal repository, non gli artefatti di build.
rm -rf "${TARGET}/auto" "${TARGET}/config" "${TARGET}/tools" \
	"${TARGET}/dist" "${TARGET}/screenshots" "${TARGET}/.git"
rm -f "${TARGET}/build.sh" "${TARGET}/build.ps1" "${TARGET}/run-qemu.sh" \
	"${TARGET}/README.md" "${TARGET}/.gitignore" "${TARGET}/.gitattributes"

cp -a "${SRC}/." "${TARGET}/"
rm -rf "${TARGET}/.git"

# Il filesystem Windows non conserva i permessi: li normalizziamo,
# ma solo sui file sorgente (mai su chroot/ e binary/, che sono artefatti).
for dir in auto config tools; do
	[ -d "${TARGET}/${dir}" ] || continue
	find "${TARGET}/${dir}" -type d -exec chmod 755 {} +
	find "${TARGET}/${dir}" -type f -exec chmod 644 {} +
done
chmod 644 "${TARGET}"/*.md "${TARGET}"/*.sh "${TARGET}"/*.ps1 2>/dev/null || true
chmod 644 "${TARGET}/.gitignore" "${TARGET}/.gitattributes" 2>/dev/null || true
chmod 755 "${TARGET}/auto/config" \
	"${TARGET}/build.sh" "${TARGET}"/tools/*.sh \
	"${TARGET}"/config/hooks/normal/*.hook.* \
	"${TARGET}"/config/includes.chroot/usr/local/bin/* 2>/dev/null || true

# live-build salva la configurazione risolta (distribuzione, bootloader,
# opzioni) in config/common, config/bootstrap, ecc. e la rigenera solo se
# manca lo stagefile .build/config. Qui sopra config/ viene sostituita con i
# soli file del repository: senza rimuovere lo stagefile la build userebbe i
# valori predefiniti (distribution "testing") e ricostruirebbe il chroot con
# la distribuzione sbagliata.
rm -f "${TARGET}/.build/config"

echo "==> Progetto sincronizzato in ${TARGET}"
