#!/bin/sh
# Bump dev-util/claude-code to the current upstream *stable* version.
#
# Only stable-keyworded ebuilds (KEYWORDS without ~) are managed;
# ~arch ebuilds are hand-picked snapshots and left alone. The previous
# stable ebuild is kept so machines can roll back easily; older ones
# are pruned (two stable versions in the tree at any time).
#
# Usage: scripts/bump-claude-code.sh [--manifest-only]
#   --manifest-only  skip the version check/rename, just regenerate Manifest
#
# Manifest generation needs portage (ebuild(1)); run on Gentoo or in a
# gentoo/stage3 container. Distfiles are hashed for all four arch/libc
# variants, so a bump downloads ~1.3 GB.

set -eu

overlay=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
pkgdir="$overlay/dev-util/claude-code"

# Newest stable-keyworded ebuild (version sort works for x.y.z upstream).
stable_ebuild=$(grep -L 'KEYWORDS="~' "$pkgdir"/claude-code-*.ebuild | sort -V | tail -n1)
[ -n "$stable_ebuild" ] || { echo "no stable-keyworded ebuild found" >&2; exit 1; }

if [ "${1:-}" != "--manifest-only" ]; then
	cur=$(basename "$stable_ebuild" .ebuild)
	cur=${cur#claude-code-}
	new=$(curl -fsS https://downloads.claude.ai/claude-code-releases/stable)
	echo "stable: current=$cur upstream=$new"
	if [ "$cur" = "$new" ]; then
		echo "up to date"
		exit 0
	fi
	# Keep $cur for easy rollback; prune older stable ebuilds.
	grep -L 'KEYWORDS="~' "$pkgdir"/claude-code-*.ebuild | sort -V | head -n -1 \
		| xargs -r git -C "$overlay" rm -q
	cp "$stable_ebuild" "$pkgdir/claude-code-$new.ebuild"
	git -C "$overlay" add "$pkgdir/claude-code-$new.ebuild"
	stable_ebuild="$pkgdir/claude-code-$new.ebuild"
fi

# Point portage at this checkout; hash distfiles into a throwaway dir.
distdir=$(mktemp -d)
trap 'rm -rf "$distdir"' EXIT
export DISTDIR="$distdir"
export PORTAGE_REPOSITORIES="
[DEFAULT]
main-repo = gentoo
[gentoo]
location = ${GENTOO_REPO:-/var/db/repos/gentoo}
[vibpe]
location = $overlay
"
for eb in "$pkgdir"/claude-code-*.ebuild; do
	ebuild "$eb" manifest
done
echo "done: $(basename "$stable_ebuild")"
