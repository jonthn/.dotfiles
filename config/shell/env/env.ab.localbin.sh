local _new_env_content

_new_env_content="${PATH}"

if [ -d "${HOME}/.local/bin" ]; then
	# Add local bin to path
	if command -v modify_colon_var >/dev/null 2>&1; then
		_new_env_content="$(modify_colon_var "${_new_env_content}" \
			"${HOME}/.local/bin" pre 2>/dev/null)"
	else
		_new_env_content="${HOME}/.local/bin:${_new_env_content}"
	fi
fi

if [ -d "${_base_localprefix}/bin" ]; then
	if command -v modify_colon_var >/dev/null 2>&1; then
		_new_env_content="$(modify_colon_var "${_new_env_content}" \
			"${_base_localprefix}/bin" pre 2>/dev/null)"
	else
		_new_env_content="${_base_localprefix}/bin:${_new_env_content}"
	fi
fi

export PATH="${_new_env_content}"

_new_env_content="${MANPATH}"

if [ -d "${HOME}/.local/man" ]; then;
	if command -v modify_colon_var >/dev/null 2>&1; then
		_new_env_content="$(modify_colon_var "${_new_env_content}" \
			"${HOME}/.local/man" pre 2>/dev/null)"
	else
		_new_env_content="${HOME}/.local/man:${_new_env_content}"
	fi
fi

if [ -d "${_base_localprefix}/man" ]; then;
	if command -v modify_colon_var >/dev/null 2>&1; then
		_new_env_content="$(modify_colon_var "${_new_env_content}" \
			"${_base_localprefix}/man" pre 2>/dev/null)"
	else
		_new_env_content="${_base_localprefix}/man:${_new_env_content}"
	fi
fi

export MANPATH="${_new_env_content}"

unset _new_env_content

# vim: set ft=sh ts=8 sw=8 tw=0 noet fdm=marker:
