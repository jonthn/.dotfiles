# add pkgsrc to env

local _new_env_content

PKGSRC_DIST_STABLE="${HSH}/pkg.stable"
PKGSRC_DIST_CURRENT="${HSH}/pkg"

PKGSRC_STABLE="${XDG_CACHE_HOME}/pkgsrc/stable"
PKGSRC_CURRENT="${XDG_CACHE_HOME}/pkgsrc/current"

case ${PKGSRC_PREFER} in
	current)
		_new_env_content="${PATH}"
		_new_env_content="$(modify_colon_var "${_new_env_content}" "${PKGSRC_DIST_CURRENT}/bin" pre 2>/dev/null)"
		_new_env_content="$(modify_colon_var "${_new_env_content}" "${PKGSRC_DIST_CURRENT}/sbin" pre 2>/dev/null)"
		export PATH="${_new_env_content}"

		_new_env_content="${MANPATH}"
		_new_env_content="$(modify_colon_var "${_new_env_content}" "${PKGSRC_DIST_CURRENT}/man" pre 2>/dev/null)"
		export MANPATH="${_new_env_content}"

		export PKGSRC="${PKGSRC_CURRENT}"
		;;
	stable)
		_new_env_content="${PATH}"
		_new_env_content="$(modify_colon_var "${_new_env_content}" "${PKGSRC_DIST_STABLE}/bin" pre 2>/dev/null)"
		_new_env_content="$(modify_colon_var "${_new_env_content}" "${PKGSRC_DIST_STABLE}/sbin" pre 2>/dev/null)"
		export PATH="${_new_env_content}"

		_new_env_content="${MANPATH}"
		_new_env_content="$(modify_colon_var "${_new_env_content}" "${PKGSRC_DIST_STABLE}/man" pre 2>/dev/null)"
		export MANPATH="${_new_env_content}"

		export PKGSRC="${PKGSRC_STABLE}"
		;;
	*)
		_new_env_content="${PATH}"
		_new_env_content="$(modify_colon_var "${_new_env_content}" "${PKGSRC_DIST_CURRENT}/bin" pre 2>/dev/null)"
		echo $_new_env_content
		_new_env_content="$(modify_colon_var "${_new_env_content}" "${PKGSRC_DIST_CURRENT}/sbin" pre 2>/dev/null)"
		echo $_new_env_content
		_new_env_content="$(modify_colon_var "${_new_env_content}" "${PKGSRC_DIST_STABLE}/bin" pre 2>/dev/null)"
		echo $_new_env_content
		_new_env_content="$(modify_colon_var "${_new_env_content}" "${PKGSRC_DIST_STABLE}/sbin" pre 2>/dev/null)"
		echo $_new_env_content
		export PATH="${_new_env_content}"

		_new_env_content="${MANPATH}"
		_new_env_content="$(modify_colon_var "${_new_env_content}" "${PKGSRC_DIST_CURRENT}/man" pre 2>/dev/null)"
		_new_env_content="$(modify_colon_var "${_new_env_content}" "${PKGSRC_DIST_STABLE}/man" pre 2>/dev/null)"
		export MANPATH="${_new_env_content}"

		export PKGSRC="${PKGSRC_CURRENT}"
		;;
esac

unset _new_env_content

# init {{{

# }}}

# vim: set ft=sh ts=8 sw=8 tw=0 noet fdm=marker:
