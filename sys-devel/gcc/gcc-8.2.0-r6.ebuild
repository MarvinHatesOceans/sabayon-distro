# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

PATCH_VER="1.7"
#UCLIBC_VER="1.0"

# Hardened gcc 4 stuff
#PIE_VER="0.6.5"
#SPECS_VER="0.2.0"
#SPECS_GCC_VER="4.4.3"
# arch/libc configurations known to be stable with {PIE,SSP}-by-default
#PIE_GLIBC_STABLE="x86 amd64 mips ppc ppc64 arm ia64"
#PIE_UCLIBC_STABLE="x86 arm amd64 mips ppc ppc64"
#SSP_STABLE="amd64 x86 mips ppc ppc64 arm"
# uclibc need tls and nptl support for SSP support
# uclibc need to be >= 0.9.33
#SSP_UCLIBC_STABLE="x86 amd64 mips ppc ppc64 arm"

inherit eutils sabayon-toolchain

DESCRIPTION="The GNU Compiler Collection"

KEYWORDS="~alpha amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd"

## Make sure we share all the USE flags in sys-devel/base-gcc
BASE_GCC_USE="fortran multilib nls nptl openmp altivec
	doc fixed-point graphite hardened
	cxx objc objc++ objc-gc vanilla"
for base_use in ${BASE_GCC_USE}; do
	RDEPEND+=" ~sys-devel/base-gcc-${PV}[${base_use}?]"
done
IUSE="${BASE_GCC_USE}"

RDEPEND="~sys-devel/base-gcc-${PV} ${RDEPEND}"

DEPEND="${RDEPEND}
	elibc_glibc? ( >=sys-libs/glibc-2.13 )
	>=${CATEGORY}/binutils-2.20"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.13 )"
fi

src_prepare() {
	sabayon-toolchain_src_prepare
	epatch "${FILESDIR}"/gcc-8.3.0-ia64-bootstrap.patch
}
