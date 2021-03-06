# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="4"

EGIT_REPO_URI="https://github.com/siefkenj/gnome-shell-windowlist.git"
EGIT_COMMIT="7ede91868efd5d75ce98065416acedf029041e33"

inherit git-r3

DESCRIPTION="Adds a window switcher to the top bar of gnome-shell"
HOMEPAGE="https://extensions.gnome.org/extension/25/window-list/"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~x86"
IUSE=""

RDEPEND="app-eselect/eselect-gnome-shell-extensions
	gnome-base/gnome-shell"
DEPEND=""

src_install() {
	insinto /usr/share/gnome-shell/extensions
	doins -r ./*@*
	dodoc README
}

pkg_postinst() {
	ebegin "Updating list of installed extensions"
	eselect gnome-shell-extensions update
	eend $?
}
