#!/bin/sh
# Bump dev-util/mcp-grafana to a new upstream release.
#
# The newest ebuild is copied to the new version and the oldest is pruned,
# so two versions stay in the tree. BDEPEND on dev-lang/go is raised when
# upstream's go.mod asks for a newer toolchain (never lowered).
#
# Usage: scripts/bump-mcp-grafana.sh <version>
#
# Expects DISTDIR to already hold ${P}.tar.gz and ${P}-deps.tar.xz as
# built by scripts/mkdeps.sh: the deps tarball is only published as a
# release asset after merge, so the Manifest must be generated from the
# local copy. Needs portage (ebuild(1)); run on Gentoo or in a
# gentoo/stage3 container.

set -eu

new=$1
: "${DISTDIR:?DISTDIR must point at the directory holding the new distfiles}"

overlay=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
pkgdir="$overlay/dev-util/mcp-grafana"
p="mcp-grafana-$new"

for f in "$p.tar.gz" "$p-deps.tar.xz"; do
	[ -f "$DISTDIR/$f" ] || { echo "missing $DISTDIR/$f" >&2; exit 1; }
done

newest=$(ls "$pkgdir"/mcp-grafana-*.ebuild | sort -V | tail -n1)
[ "$newest" != "$pkgdir/$p.ebuild" ] || { echo "$p already in tree"; exit 0; }

# Keep the current newest for easy rollback; prune everything older.
ls "$pkgdir"/mcp-grafana-*.ebuild | sort -V | head -n -1 \
	| xargs -r git -C "$overlay" rm -q
cp "$newest" "$pkgdir/$p.ebuild"

# Raise the Go floor if upstream now needs a newer toolchain.
want=$(tar -xzOf "$DISTDIR/$p.tar.gz" "$p/go.mod" \
	| sed -nE 's/^go ([0-9.]+)$/\1/p')
have=$(sed -nE 's/.*>=dev-lang\/go-([0-9.]+).*/\1/p' "$pkgdir/$p.ebuild")
if [ -n "$want" ] && [ -n "$have" ] && \
	[ "$(printf '%s\n%s\n' "$have" "$want" | sort -V | tail -n1)" != "$have" ]; then
	echo "go: raising BDEPEND $have -> $want"
	sed -i -E "s/>=dev-lang\/go-$have/>=dev-lang\/go-$want/" "$pkgdir/$p.ebuild"
fi
git -C "$overlay" add "$pkgdir/$p.ebuild"

export PORTAGE_REPOSITORIES="
[DEFAULT]
main-repo = gentoo
[gentoo]
location = ${GENTOO_REPO:-/var/db/repos/gentoo}
[vibpe]
location = $overlay
"
ebuild "$pkgdir/$p.ebuild" manifest
echo "done: $p.ebuild"
