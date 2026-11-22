#!/bin/bash
# Peach OS -- genera il repository apt nella cartella servita da GitHub Pages.
#
# Richiede: apt-utils (apt-ftparchive), gpg, dpkg-deb.
# La chiave privata di firma deve restare al manutentore: NON va committata.
# Per usare una chiave diversa: PEACH_GPG_UID="..." ./tools/build-repo.sh
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"

GPG_UID="${PEACH_GPG_UID:-Peach OS Repository <peach-os@artiombilash9-ctrl.github.io>}"
REPO="docs/repo"
POOL="$REPO/pool/main"
DIST="$REPO/dists/stable"
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT

if ! gpg --list-secret-keys "$GPG_UID" >/dev/null 2>&1; then
	echo "Errore: chiave GPG '$GPG_UID' non trovata." >&2
	echo "Generala con: gpg --batch --passphrase '' --quick-generate-key \"$GPG_UID\" rsa3072 sign 0" >&2
	exit 1
fi

echo "==> cartelle del repository"
mkdir -p "$POOL/p/peach-os-repo" "$DIST/main/binary-amd64" \
	config/includes.chroot/etc/apt/keyrings \
	config/includes.chroot/etc/apt/sources.list.d

echo "==> chiave pubblica"
gpg --export "$GPG_UID" > "$REPO/peach-os-archive-keyring.gpg"
cp "$REPO/peach-os-archive-keyring.gpg" config/includes.chroot/etc/apt/keyrings/peach-os.gpg
cp repo-src/peach-os-repo/etc/apt/sources.list.d/peach-os.list \
	config/includes.chroot/etc/apt/sources.list.d/peach-os.list

echo "==> pacchetto peach-os-repo"
cp -a repo-src/peach-os-repo "$BUILD/peach-os-repo"
mkdir -p "$BUILD/peach-os-repo/etc/apt/keyrings"
install -m 0644 "$REPO/peach-os-archive-keyring.gpg" \
	"$BUILD/peach-os-repo/etc/apt/keyrings/peach-os.gpg"
chmod 0755 "$BUILD/peach-os-repo/DEBIAN"
find "$BUILD/peach-os-repo/etc" -type d -exec chmod 0755 {} +
find "$BUILD/peach-os-repo/etc" -type f -exec chmod 0644 {} +
dpkg-deb --root-owner-group --build -Zxz "$BUILD/peach-os-repo" \
	"$POOL/p/peach-os-repo/peach-os-repo_1.0_all.deb"

echo "==> indici"
( cd "$REPO" && apt-ftparchive packages pool/main > "$ROOT/$DIST/main/binary-amd64/Packages" )
gzip -9 -c "$DIST/main/binary-amd64/Packages" > "$DIST/main/binary-amd64/Packages.gz"
rm -f "$DIST/Release" "$DIST/InRelease" "$DIST/Release.gpg"
( cd "$REPO" && apt-ftparchive \
	-o APT::FTPArchive::Release::Origin="Peach OS" \
	-o APT::FTPArchive::Release::Label="Peach OS" \
	-o APT::FTPArchive::Release::Suite="stable" \
	-o APT::FTPArchive::Release::Codename="stable" \
	-o APT::FTPArchive::Release::Architectures="amd64 all" \
	-o APT::FTPArchive::Release::Components="main" \
	-o APT::FTPArchive::Release::Description="Repository ufficiale Peach OS" \
	release dists/stable > dists/stable/Release )

echo "==> firma"
gpg --batch --yes --clearsign -o "$DIST/InRelease" "$DIST/Release"
gpg --batch --yes --detach-sign --armor -o "$DIST/Release.gpg" "$DIST/Release"

echo "==> fatto"
find "$REPO" -type f | sed "s|^$REPO/||" | sort
sha256sum "$POOL/p/peach-os-repo/peach-os-repo_1.0_all.deb"
