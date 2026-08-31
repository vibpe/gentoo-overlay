#!/bin/sh
# Canonical Go module deps tarball builder.
#
# Usage: mkdeps.sh <owner/repo> <version>
# Produces <name>-<version>-deps.tar.xz in the current directory.
#
# The output must be byte-reproducible: the maintainer runs this locally
# before `ebuild ... manifest`, and the deps-sync workflow rebuilds it in CI
# and verifies the result against the Manifest hash before publishing.
# Hence the fixed tar metadata and single-threaded xz.
set -eu

PKG=$1
VER=$2
NAME=${PKG##*/}
P="${NAME}-${VER}"

curl -fsSL "https://github.com/${PKG}/archive/refs/tags/v${VER}.tar.gz" -o "${P}.tar.gz"
rm -rf "${P}" go-mod
tar xf "${P}.tar.gz"
(cd "${P}" && GOMODCACHE="${PWD}/../go-mod" go mod download -modcacherw)
# sumdb tiles vary between fetches (the transparency log grows upstream) and
# are not needed at build time (go.sum + ziphashes cover verification offline).
tar --sort=name --owner=0 --group=0 --numeric-owner --mtime=@0 \
	--exclude=go-mod/cache/download/sumdb \
	-cf "${P}-deps.tar" go-mod
xz -9 -T1 -f "${P}-deps.tar"
ls -l "${P}-deps.tar.xz"
