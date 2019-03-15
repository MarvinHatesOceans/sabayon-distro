# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cmake-utils pax-utils systemd user versionator

MY_P=${P/-core}
MY_PN=${PN/-core}

DESCRIPTION="Qt/KDE IRC client - the \"core\" (server) component"
HOMEPAGE="http://quassel-irc.org/"
SRC_URI="http://quassel-irc.org/pub/${MY_P}.tar.bz2"
KEYWORDS="~amd64 ~x86"

LICENSE="GPL-3"
SLOT="0"
IUSE="crypt postgres +ssl syslog"

SERVER_RDEPEND="
	dev-qt/qtscript:5
	crypt? ( app-crypt/qca:2[qt5(+),ssl] )
	postgres? ( dev-qt/qtsql:5[postgres] )
	!postgres? ( dev-qt/qtsql:5[sqlite] dev-db/sqlite:3[threadsafe(+),-secure-delete] )
	syslog? ( virtual/logger )
"

RDEPEND="
	dev-qt/qtcore:5
	dev-qt/qtnetwork:5[ssl?]
	sys-libs/zlib
	${SERVER_RDEPEND}
"
DEPEND="
	${RDEPEND}
	!net-irc/quassel-core-bin
	kde-frameworks/extra-cmake-modules
	"

DOCS=( AUTHORS ChangeLog README.md )

S="${WORKDIR}/${MY_P}"

pkg_setup() {
	QUASSEL_DIR=/var/lib/${MY_PN}
	QUASSEL_USER=${MY_PN}
	# create quassel:quassel user
	enewgroup "${QUASSEL_USER}"
	enewuser "${QUASSEL_USER}" -1 -1 "${QUASSEL_DIR}" "${QUASSEL_USER}"
}

src_configure() {
	local mycmakeargs=(
		$(cmake-utils_use_find_package crypt QCA2-QT5)
		# $(cmake-utils_use_find_package dbus dbusmenu-qt5)
		#$(cmake-utils_use_find_package dbus Qt5DBus)
		"-DWITH_KDE=OFF"
		"-DWITH_OXYGEN=OFF"
		"-DWANT_MONO=OFF"

		"CMAKE_DISABLE_FIND_PACKAGE_Phonon4Qt5=ON"
		-DUSE_QT5=ON
		-DEMBED_DATA=OFF
		-DCMAKE_SKIP_RPATH=ON
		"-DWANT_CORE=ON"
		"CMAKE_DISABLE_FIND_PACKAGE_LibsnoreQt5=ON"
		"-DWITH_WEBKIT=OFF"
		"-DWANT_QTCLIENT=OFF"
	)

	# Something broke upstream detection since Qt 5.5
	if use ssl ; then
		mycmakeargs+=( "-DHAVE_SSL=TRUE" )
	fi

	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install

	rm -r "${ED}"usr/share/quassel/translations || die
	rmdir "${ED}"usr/share/quassel || die # should be empty
	rm -f "${ED}"usr/share/pixmaps/quassel.png || die
	rm -f "${ED}"usr/share/icons/hicolor/48x48/apps/quassel.png || die

	# server stuff

	# needs PAX marking wrt bug#346255
	pax-mark m "${ED}/usr/bin/quasselcore"

	# prepare folders in /var/
	keepdir "${QUASSEL_DIR}"
	fowners "${QUASSEL_USER}":"${QUASSEL_USER}" "${QUASSEL_DIR}"

	# init scripts & systemd unit
	newinitd "${FILESDIR}"/quasselcore.init-r1 quasselcore
	newconfd "${FILESDIR}"/quasselcore.conf-r1 quasselcore
	systemd_dounit "${FILESDIR}"/quasselcore.service

	# logrotate
	insinto /etc/logrotate.d
	newins "${FILESDIR}/quassel.logrotate" quassel
}

pkg_postinst() {
	einfo "If you want to generate SSL certificate remember to run:"
	einfo "	emerge --config =${CATEGORY}/${PF}"

	# server || monolithic
	einfo "Quassel can use net-misc/oidentd package if installed on your system."
	einfo "Consider installing it if you want to run quassel within identd daemon."
}

pkg_config() {
	if use ssl; then
		# generate the pem file only when it does not already exist
		if [ ! -f "${QUASSEL_DIR}/quasselCert.pem" ]; then
			einfo "Generating QUASSEL SSL certificate to: \"${QUASSEL_DIR}/quasselCert.pem\""
			openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
				-keyout "${QUASSEL_DIR}/quasselCert.pem" \
				-out "${QUASSEL_DIR}/quasselCert.pem"
			# permissions for the key
			chown ${QUASSEL_USER}:${QUASSEL_USER} "${QUASSEL_DIR}/quasselCert.pem"
			chmod 400 "${QUASSEL_DIR}/quasselCert.pem"
		else
			einfo "Certificate \"${QUASSEL_DIR}/quasselCert.pem\" already exists."
			einfo "Remove it if you want to create new one."
		fi
	fi
}
