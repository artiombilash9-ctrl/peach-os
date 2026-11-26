#!/bin/bash
# Peach OS -- suddivide le ISO in parti < 2 GiB per GitHub Releases.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p release-assets

for arch in amd64 i386; do
	ISO="dist/PeachOS-1.0-${arch}.iso"
	[ -f "$ISO" ] || { echo "ISO mancante: $ISO" >&2; exit 1; }
	rm -f release-assets/PeachOS-1.0-${arch}.iso.part*
	split -b 1800m -d -a 2 "$ISO" "release-assets/PeachOS-1.0-${arch}.iso.part"
	sha256sum "$ISO" > "release-assets/PeachOS-1.0-${arch}.iso.sha256"
done

echo "=== asset prodotti ==="
ls -lh release-assets/
 echo "=== somme ==="
sha256sum release-assets/*.part* | head -10
