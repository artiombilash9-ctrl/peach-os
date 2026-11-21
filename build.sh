#!/usr/bin/env bash
#
# Costruisce la ISO di Peach OS.
#
# Requisiti: Debian 13 (trixie) o ambiente equivalente, root, live-build.
# Su Windows usare invece build.ps1 (che prepara tutto dentro WSL).
#
#   sudo ./build.sh          # build completa
#   sudo ./build.sh --debug  # passa opzioni a lb build
#
set -euo pipefail
cd "$(dirname "$0")"

if [ "$(id -u)" -ne 0 ]; then
	echo "Errore: la build richiede root (live-build crea un chroot)." >&2
	echo "        Usa: sudo ./build.sh" >&2
	exit 1
fi

if ! command -v lb >/dev/null 2>&1; then
	echo "Errore: live-build non trovato." >&2
	echo "        Su Debian 13: sudo apt install live-build debootstrap \\" >&2
	echo "          debian-archive-keyring syslinux-common isolinux grub-pc-bin \\" >&2
	echo "          grub-efi-amd64-bin mtools dosfstools squashfs-tools xorriso" >&2
	exit 1
fi

# I file di configurazione devono essere eseguibili.
chmod +x auto/config
chmod +x config/hooks/normal/*.hook.chroot 2>/dev/null || true
chmod +x config/includes.chroot/usr/local/bin/* 2>/dev/null || true

mkdir -p dist

lb build "$@"

ISO="$(ls -1 ./*.hybrid.iso 2>/dev/null | head -n1 || true)"
if [ -z "${ISO}" ]; then
	echo "Errore: ISO non trovata dopo la build." >&2
	exit 1
fi

OUT="dist/PeachOS-1.0-amd64.iso"
mv -f "${ISO}" "${OUT}"
( cd dist && sha256sum "PeachOS-1.0-amd64.iso" > "PeachOS-1.0-amd64.iso.sha256" )

echo
echo "==> ISO pronta: ${OUT} ($(du -h "${OUT}" | cut -f1))"
echo "==> Avvio in QEMU: ./run-qemu.sh"
