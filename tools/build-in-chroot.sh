#!/bin/bash
#
# Esegue la build dentro il chroot Debian 13 preparato da setup-build-env.sh.
#
#   bash tools/build-in-chroot.sh
#
set -euo pipefail

TARGET="${TARGET:-/srv/peach-build}"
BUILD_DIR="${BUILD_DIR:-/build/peach-os}"

if [ "$(id -u)" -ne 0 ]; then
	echo "Errore: eseguire come root (wsl -u root)." >&2
	exit 1
fi

if [ ! -x "${TARGET}/bin/bash" ]; then
	echo "Errore: ambiente ${TARGET} mancante. Esegui tools/setup-build-env.sh." >&2
	exit 1
fi

if [ ! -x "${TARGET}${BUILD_DIR}/build.sh" ]; then
	echo "Errore: progetto non sincronizzato in ${BUILD_DIR}." >&2
	echo "        Esegui tools/sync-to-wsl.sh." >&2
	exit 1
fi

mkdir -p "${TARGET}/proc" "${TARGET}/sys" "${TARGET}/dev/pts"
mountpoint -q "${TARGET}/proc"    || mount --bind /proc "${TARGET}/proc"
mountpoint -q "${TARGET}/sys"     || mount --bind /sys "${TARGET}/sys"
mountpoint -q "${TARGET}/dev"     || mount --bind /dev "${TARGET}/dev"
mountpoint -q "${TARGET}/dev/pts" || mount --bind /dev/pts "${TARGET}/dev/pts"

chroot "${TARGET}" /bin/bash -c "cd ${BUILD_DIR} && exec ./build.sh"
