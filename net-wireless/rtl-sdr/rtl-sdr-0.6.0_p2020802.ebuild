# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake multilib

DESCRIPTION="turns your Realtek RTL2832 based DVB dongle into a SDR receiver"
HOMEPAGE="http://sdr.osmocom.org/trac/wiki/rtl-sdr"

if [[ ${PV} == 9999* ]]; then
	inherit git-r3
	SRC_URI=""
	EGIT_REPO_URI="https://git.osmocom.org/${PN}"
else
	#git clone https://git.osmocom.org/rtl-sdr
	#cd rtl-sdr
	#git archive --format=tar --prefix=rtl-sdr-${PV}/ master | xz > ../rtl-sdr-${PV}.tar.xz
	#SRC_URI="https://dev.gentoo.org/~zerochaos/distfiles/${P}.tar.xz"

	COMMIT="ed0317e6a58c098874ac58b769cf2e609c18d9a5"
	SRC_URI="https://github.com/osmocom/rtl-sdr/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${PN}-${COMMIT}"
	KEYWORDS="amd64 ~arm ~arm64 ~ppc ~ppc64 ~x86"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE="+zerocopy"

DEPEND="virtual/libusb:1"
RDEPEND="${DEPEND}"

src_unpack() {
	if [[ ${PV} == 9999* ]]; then
		git-r3_src_unpack
	else
		default
	fi
}

src_prepare() {
	sed -i 's#VERSION_INFO_PATCH_VERSION git#VERSION_INFO_PATCH_VERSION 0_p20200802#' CMakeLists.txt
	cmake_src_prepare
}

src_configure() {
	#the udev rules are 666, we don't want that
	mycmakeargs=(
		-DINSTALL_UDEV_RULES=OFF
		-DDETACH_KERNEL_DRIVER=ON
		-DENABLE_ZEROCOPY="$(usex zerocopy)"
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install
	newinitd "${FILESDIR}"/rtl_tcp.initd rtl_tcp
	newconfd "${FILESDIR}"/rtl_tcp.confd rtl_tcp
}

pkg_postinst() {
	elog "Only users in the usb group can capture."
	elog "Just run 'gpasswd -a <USER> usb', then have <USER> re-login."
}
