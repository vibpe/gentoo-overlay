# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Model Context Protocol (MCP) server for Grafana"
HOMEPAGE="https://github.com/grafana/mcp-grafana"
SRC_URI="https://github.com/grafana/mcp-grafana/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/vibpe/gentoo-overlay/releases/download/${P}/${P}-deps.tar.xz"

LICENSE="Apache-2.0"
LICENSE+=" BSD BSD-2 ISC MIT MPL-2.0"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND=">=dev-lang/go-1.26.5"

src_compile() {
	ego build -o ${PN} ./cmd/${PN}
}

src_install() {
	dobin ${PN}
	einstalldocs
}
