# late shell PATH and initialisation

local _new_env_content

_new_env_content="${PATH}"
if [ -d "${HOME}/.local/bin" ]; then;
	_new_env_content="$(modify_colon_var "${_new_env_content}" \
		"${HOME}/.local/bin" pre 2>/dev/null)"
fi
if [ -d "${_base_localprefix}/bin" ]; then;
	_new_env_content="$(modify_colon_var "${_new_env_content}" \
		"${_base_localprefix}/bin" pre 2>/dev/null)"
fi
export PATH="${_new_env_content}"

_new_env_content="${MANPATH}"
if [ -d "${HOME}/.local/man" ]; then;
	_new_env_content="$(modify_colon_var "${_new_env_content}" \
		"${HOME}/.local/bin" pre 2>/dev/null)"
fi
if [ -d "${_base_localprefix}/man" ]; then;
	_new_env_content="$(modify_colon_var "${_new_env_content}" \
		"${_base_localprefix}/man" pre 2>/dev/null)"
fi
export MANPATH="${_new_env_content}"

unset _new_env_content

# init {{{

local zoxide_cmd
zoxide_cmd=$(shf_shell_zoxide location 2>/dev/null)

if command -v zoxide >/dev/null 2>&1; then
	zoxide_cmd=zoxide
elif [ -z ${zoxide_cmd} -o ! -x ${zoxide_cmd} ]; then
	shf_shell_zoxide init
	[ ! -x ${zoxide_cmd} ] && zoxide_cmd=''
fi
if [ -n "${zoxide_cmd}" ]; then
	case $(__shell) in
		zsh)
			eval "$("${zoxide_cmd}" init zsh)"
			;;
		bash)
			eval "$("${zoxide_cmd}" init bash)"
			;;
		*)
			eval "$("${zoxide_cmd}" init posix --hook prompt)"
			;;
	esac
fi

# }}}

# vim: set ft=sh ts=8 sw=8 tw=0 noet fdm=marker:
