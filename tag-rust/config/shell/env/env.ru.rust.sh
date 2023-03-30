# add rust to env

local _new_env_content

export CARGO_INSTALL_ROOT="${_base_localprefix}/rust"
export CARGO_HOME=${XDG_CACHE_HOME}/cargo
export RUSTUP_HOME=${XDG_CACHE_HOME}/rustup

_new_env_content="${PATH}"
_new_env_content="$(modify_colon_var "${_new_env_content}" "${CARGO_INSTALL_ROOT}/bin" pre 2>/dev/null)"
_new_env_content="$(modify_colon_var "${_new_env_content}" "${CARGO_HOME}/bin" pre 2>/dev/null)"
export PATH="${_new_env_content}"

unset _new_env_content

# vim: set ft=sh ts=8 sw=8 tw=0 noet :
