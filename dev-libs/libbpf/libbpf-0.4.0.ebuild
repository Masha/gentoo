# Copyright 2019-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic toolchain-funcs

if [[ ${PV} =~ [9]{4,} ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/libbpf/libbpf.git"
else
	SRC_URI="https://github.com/libbpf/libbpf/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86"
fi
S="${WORKDIR}/${P}/src"

HOMEPAGE="https://github.com/libbpf/libbpf"
DESCRIPTION="Stand-alone build of libbpf from the Linux kernel"

LICENSE="GPL-2 LGPL-2.1 BSD-2"
SLOT="0/${PV}"
IUSE="+static-libs"

COMMON_DEPEND="
	virtual/libelf
"
DEPEND="
	${COMMON_DEPEND}
	sys-kernel/linux-headers
"
RDEPEND="
	${COMMON_DEPEND}
"

PATCHES=(
	"${FILESDIR}/libbpf-0.3.0-paths.patch"
)

src_compile() {
	append-cflags -fPIC
	emake \
		BUILD_SHARED=y \
		LIBSUBDIR="$(get_libdir)" \
		CC="$(tc-getCC)" \
		AR="$(tc-getAR)" \
		V=1
}

src_install() {
	emake \
		BUILD_SHARED=y \
		LIBSUBDIR="$(get_libdir)" \
		DESTDIR="${D}" \
		install install_uapi_headers

	insinto /usr/$(get_libdir)/pkgconfig
	doins ${PN}.pc

	if ! use static-libs; then
		find "${D}" -name '*.a' -delete || die
	fi
}
