#!/bin/bash
# Peach OS -- costruisce la variante i386 (32 bit) su Debian 12 bookworm.
#
# Debian 13 trixie non pubblica piu' kernel i386: la variante 32 bit usa
# bookworm con kernel 686-pae. La ISO resta dist/PeachOS-1.0-i386.iso.
#
# Va eseguito da WSL (root), dentro l'ambiente di build Debian gia' pronto.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILDROOT=/srv/peach-build
VARIANT="$BUILDROOT/build/peach-os-i386"
OUT="$SRC/dist/PeachOS-1.0-i386.iso"

echo "==> prepara albero di build i386"
rm -rf "$VARIANT"
mkdir -p "$VARIANT/dist"
cp -a "$SRC/auto" "$SRC/config" "$SRC/build.sh" "$VARIANT/"

sed -i \
	-e 's/--distribution trixie/--distribution bookworm/' \
	-e 's/--architectures amd64/--architectures i386/' \
	-e 's/--linux-flavours amd64/--linux-flavours 686-pae/' \
	-e 's/--image-name peachos/--image-name peachos-i386/' \
	-e 's/Peach OS 1.0 .Trixie./Peach OS 1.0 "Bookworm"/' \
	"$VARIANT/auto/config"

sed -i 's/PeachOS-1\.0-amd64\.iso/PeachOS-1.0-i386.iso/g' "$VARIANT/build.sh"

# fastfetch non esiste in bookworm/i386
sed -i '/^fastfetch$/d' "$VARIANT/config/package-lists/01-core.list.chroot"

# Nella variante 32 bit la base e' bookworm: allinea etichette e splash.
grep -rl -e 'Debian 13' -e 'Trixie' "$VARIANT/config" 2>/dev/null | while read -r f; do
	sed -i -e 's/Debian 13/Debian 12/g' -e 's/Trixie/Bookworm/g' "$f"
done

chmod +x "$VARIANT/auto/config" "$VARIANT/build.sh"
chmod +x "$VARIANT"/config/hooks/normal/*.hook.* 2>/dev/null || true

echo "==> configurazione i386"
grep -E 'distribution|architectures|linux-flavours|bootloaders|uefi-secure' "$VARIANT/auto/config"

echo "==> build (chroot Debian, circa 20 min)"
mkdir -p "$BUILDROOT/proc" "$BUILDROOT/sys" "$BUILDROOT/dev/pts"
mountpoint -q "$BUILDROOT/proc"    || mount --bind /proc "$BUILDROOT/proc"
mountpoint -q "$BUILDROOT/sys"     || mount --bind /sys "$BUILDROOT/sys"
mountpoint -q "$BUILDROOT/dev"     || mount --bind /dev "$BUILDROOT/dev"
mountpoint -q "$BUILDROOT/dev/pts" || mount --bind /dev/pts "$BUILDROOT/dev/pts"

chroot "$BUILDROOT" /bin/bash -c 'cd /build/peach-os-i386 && exec ./build.sh --full'

echo "==> copia ISO nella cartella dist del progetto"
mkdir -p "$SRC/dist"
cp -f "$VARIANT/dist/PeachOS-1.0-i386.iso" "$OUT"
( cd "$SRC/dist" && sha256sum PeachOS-1.0-i386.iso > PeachOS-1.0-i386.iso.sha256 )
ls -lh "$OUT"
sha256sum "$OUT"
echo "==> fatto"
