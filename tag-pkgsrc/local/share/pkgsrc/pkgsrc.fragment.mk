#PKG_DEVELOPER=			yes
#PKG_DEBUG_LEVEL=		1
MAKE_JOBS=			3
PKGSRC_MKPIE=			yes

OSX_SDK_PATH=                   /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
OSX_TOLERATE_SDK_SKEW=		yes

ACCEPTABLE_LICENSES+=		vim-license lame-license unrar-license

PKGSRC_FORTRAN=			gfortran
RUST_TYPE=                      bin

.if ${OPSYS} == Darwin
CWRAPPERS_PREPEND.ld+=		-headerpad_max_install_names
CWRAPPERS_PREPEND.cc+=          -isysroot ${OSX_SDK_PATH}
CWRAPPERS_PREPEND.cxx+=         -isysroot ${OSX_SDK_PATH}
LDFLAGS+=			-Wl,-headerpad_max_install_names
PKG_DEFAULT_OPTIONS=            inet6 -x11 -doc
.elif ${OPSYS} == Linux
PKG_DEFAULT_OPTIONS=            -doc
#SSLCERTBUNDLE=			${SSLDIR}/certs/ca-certificates.crt
.endif

PKG_OPTIONS.vim+=		lua
PKG_OPTIONS.curl=		-idn


