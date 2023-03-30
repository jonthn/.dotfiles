#PKG_DEVELOPER=			yes
#PKG_DEBUG_LEVEL=		1
MAKE_JOBS=			3
PKGSRC_MKPIE=			yes

PKG_SYSCONFDIR.openssl=		/etc/ssl

OSX_TOLERATE_SDK_SKEW=		yes

ACCEPTABLE_LICENSES+=		vim-license lame-license unrar-license

PKGSRC_FORTRAN=			gfortran

.if ${OPSYS} == Darwin
PKG_DEFAULT_OPTIONS=            inet6 -x11 -doc
LDFLAGS+=			-Wl,-headerpad_max_install_names
CWRAPPERS_PREPEND.ld+=		-headerpad_max_install_names
.elif ${OPSYS} == Linux
SSLCERTBUNDLE=			${SSLDIR}/certs/ca-certificates.crt
.endif

PKG_OPTIONS.vim+=		lua python ruby
PKG_OPTIONS.curl=		-idn


