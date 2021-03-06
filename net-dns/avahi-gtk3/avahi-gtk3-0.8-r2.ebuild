# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

AVAHI_MODULE="${AVAHI_MODULE:-${PN/avahi-}}"
MY_P=${P/-${AVAHI_MODULE}}
MY_PN=${PN/-${AVAHI_MODULE}}

PYTHON_COMPAT=( python3_{6,7,8} )
PYTHON_REQ_USE="gdbm"

inherit autotools eutils flag-o-matic python-r1 systemd

DESCRIPTION="System which facilitates service discovery on a local network (gtk3 pkg)"
HOMEPAGE="http://avahi.org/"
SRC_URI="https://github.com/lathiat/avahi/archive/v${PV}.tar.gz -> ${MY_P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~x86-linux"
IUSE="bookmarks dbus gdbm +introspection nls python"

S="${WORKDIR}/${MY_P}"

COMMON_DEPEND="
	dbus? ( sys-apps/dbus )
	~net-dns/avahi-base-${PV}[bookmarks=,dbus=,gdbm=,introspection=,nls=,python=]
	x11-libs/gtk+:3
	dev-python/pygobject:3[${PYTHON_USEDEP}]
	!<net-dns/avahi-gtk-0.7
	introspection? ( dev-libs/gobject-introspection:= )
	python? (
		${PYTHON_DEPS}
		dbus? ( dev-python/dbus-python[${PYTHON_USEDEP}] )
		introspection? ( dev-python/pygobject:3[${PYTHON_USEDEP}] )
	)
"

DEPEND="${COMMON_DEPEND}
	dev-util/glib-utils"
RDEPEND="${COMMON_DEPEND}"

src_prepare() {
	default

	# Prevent .pyc files in DESTDIR
	>py-compile

	eautoreconf

	# bundled manpages
}

src_configure() {
	use python && python_setup

	local myconf=(
		--disable-static
		--localstatedir="${EPREFIX}/var"
		--with-distro=gentoo
		--disable-python-dbus
		--disable-manpages
		--disable-xmltoman
		--disable-mono
		--disable-monodoc
		--enable-glib
		--enable-gobject
		$(use_enable dbus)
		$(use_enable python)
		$(use_enable nls)
		$(use_enable introspection)
		--disable-qt3
		--disable-qt4
		--disable-qt5
		--disable-gtk
		--enable-gtk3
		$(use_enable gdbm)
		--with-systemdsystemunitdir="$(systemd_get_systemunitdir)"
	)

	if use python; then
		myconf+=(
			$(use_enable dbus python-dbus)
			$(use_enable introspection pygobject)
		)
	fi

	econf "${myconf[@]}"
}

src_compile() {
	for target in avahi-common avahi-client avahi-glib avahi-ui avahi-core; do
		emake -C "${target}" || die
	done
	emake avahi-ui-gtk3.pc || die
}

src_install() {
	if use python; then
		emake -C avahi-python/avahi-discover install DESTDIR="${D}" || die
	fi
	emake -C avahi-discover-standalone DESTDIR="${D}" install || die
	emake -C avahi-ui DESTDIR="${D}" install || die
	dodir /usr/$(get_libdir)/pkgconfig
	insinto /usr/$(get_libdir)/pkgconfig
	doins avahi-ui-gtk3.pc
	prune_libtool_files --all
	use bookmarks && use python && use dbus || \
	rm -f "${D}"/usr/bin/avahi-bookmarks
}
