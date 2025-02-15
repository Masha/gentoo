# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..10} pypy3 )
PYTHON_REQ_USE="threads(+)"

inherit distutils-r1 multiprocessing

VEC_P=cryptography_vectors-${PV}
DESCRIPTION="Library providing cryptographic recipes and primitives"
HOMEPAGE="https://github.com/pyca/cryptography/ https://pypi.org/project/cryptography/"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz
	test? ( mirror://pypi/c/cryptography_vectors/${VEC_P}.tar.gz )"

LICENSE="|| ( Apache-2.0 BSD )"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 hppa ~ia64 ~mips ppc ppc64 ~riscv sparc x86"

RDEPEND="
	$(python_gen_cond_dep '
		>=dev-python/cffi-1.8:=[${PYTHON_USEDEP}]
	' 'python*')
	"
BDEPEND="
	test? (
		>=dev-python/hypothesis-1.11.4[${PYTHON_USEDEP}]
		dev-python/iso8601[${PYTHON_USEDEP}]
		dev-python/pretend[${PYTHON_USEDEP}]
		dev-python/pyasn1-modules[${PYTHON_USEDEP}]
		dev-python/pytz[${PYTHON_USEDEP}]
		dev-python/pytest-subtests[${PYTHON_USEDEP}]
		dev-python/pytest-xdist[${PYTHON_USEDEP}]
	)"

distutils_enable_tests pytest

DEPEND="
	>=dev-libs/openssl-1.0.2o-r6:0=
	"
RDEPEND+=${DEPEND}

PATCHES=(
	"${FILESDIR}/${P}-py310.patch"
)

src_prepare() {
	default

	# avoid automagic dependency on dev-libs/openssl[sslv3]
	# https://bugs.gentoo.org/789450
	export CPPFLAGS="${CPPFLAGS} -DOPENSSL_NO_SSL3_METHOD=1"

	# work around availability macros not supported in GCC (yet)
	if [[ ${CHOST} == *-darwin* ]] ; then
		local darwinok=0
		if [[ ${CHOST##*-darwin} -ge 16 ]] ; then
			darwinok=1
		fi
		sed -i -e 's/__builtin_available(macOS 10\.12, \*)/'"${darwinok}"'/' \
			src/_cffi_src/openssl/src/osrandom_engine.c || die
	fi

	# this version does not really use Rust, it just creates a dummy
	# extension to break stuff
	export CRYPTOGRAPHY_DONT_BUILD_RUST=1
	sed -e 's:from setuptools_rust import RustExtension:pass:' \
		-e '/setup_requires/d' \
		-i setup.py || die
}

python_test() {
	local -x PYTHONPATH=${PYTHONPATH}:${WORKDIR}/${VEC_P}
	epytest -n "$(makeopts_jobs "${MAKEOPTS}" "$(get_nproc)")"
}
