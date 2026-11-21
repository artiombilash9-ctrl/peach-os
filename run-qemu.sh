#!/usr/bin/env bash
#
# Avvia Peach OS in QEMU (BIOS) per provarla senza masterizzare nulla.
#
#   ./run-qemu.sh [percorso-iso]
#
set -euo pipefail
cd "$(dirname "$0")"

ISO="${1:-dist/PeachOS-1.0-amd64.iso}"

if [ ! -f "${ISO}" ]; then
	echo "Errore: ${ISO} non trovato. Esegui prima ./build.sh" >&2
	exit 1
fi

if [ ! -e /dev/kvm ]; then
	echo "Avviso: /dev/kvm non disponibile, l'avvio sara' lento (emulazione)." >&2
	KVM=""
else
	KVM="-enable-kvm"
fi

exec qemu-system-x86_64 \
	-m 3072 \
	-smp 2 \
	${KVM} \
	-cdrom "${ISO}" \
	-boot d \
	-vga std \
	-netdev user,id=net0 -device e1000,netdev=net0 \
	-usb -device usb-tablet \
	-display gtk,zoom-to-fit=on
