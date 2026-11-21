#!/bin/bash
#
# Prepara un ambiente di build Debian 13 (trixie) nativo.
#
# Va eseguito come root in WSL (o su qualsiasi Linux con debootstrap):
#   wsl -d Ubuntu -u root -- bash tools/setup-build-env.sh
#
# Crea un chroot in $TARGET con live-build e tutti gli strumenti
# necessari a produrre una ISO ibrida BIOS + UEFI.
#
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
export LANG=C

TARGET="${TARGET:-/srv/peach-build}"
MIRROR="${MIRROR:-http://deb.debian.org/debian}"

if [ "$(id -u)" -ne 0 ]; then
	echo "Errore: eseguire come root." >&2
	exit 1
fi

if [ ! -x "${TARGET}/bin/bash" ]; then
	echo "==> debootstrap Debian 13 (trixie) in ${TARGET}"
	debootstrap --arch=amd64 --variant=minbase \
		--include=ca-certificates,apt-utils,locales \
		trixie "${TARGET}" "${MIRROR}"
fi

cat > "${TARGET}/etc/apt/sources.list" <<EOF
deb ${MIRROR} trixie main contrib non-free non-free-firmware
deb ${MIRROR} trixie-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
EOF

# I mount servono a debootstrap/live-build per lavorare nel chroot.
mkdir -p "${TARGET}/proc" "${TARGET}/sys" "${TARGET}/dev/pts"
mountpoint -q "${TARGET}/proc"    || mount --bind /proc "${TARGET}/proc"
mountpoint -q "${TARGET}/sys"     || mount --bind /sys "${TARGET}/sys"
mountpoint -q "${TARGET}/dev"     || mount --bind /dev "${TARGET}/dev"
mountpoint -q "${TARGET}/dev/pts" || mount --bind /dev/pts "${TARGET}/dev/pts"

echo "==> installazione strumenti di build"
chroot "${TARGET}" /bin/bash -c "apt-get update -qq && apt-get install -y -qq \
	live-build mmdebstrap debootstrap debian-archive-keyring \
	syslinux-common syslinux-utils isolinux grub-efi-amd64-bin grub-pc-bin \
	mtools dosfstools squashfs-tools xorriso xz-utils rsync file \
	>/dev/null"

echo "==> ambiente pronto"
chroot "${TARGET}" /bin/bash -c "lb --version"
