#PKG_DEVELOPER=			yes
#PKG_DEBUG_LEVEL=		1
MAKE_JOBS=			3

ACCEPTABLE_LICENSES+=		vim-license lame-license unrar-license

PKGSRC_FORTRAN=gfortran

.if ${OPSYS} == Darwin
PKG_DEFAULT_OPTIONS=            -x11
.endif
PKG_OPTIONS.vim+=		lua python ruby

