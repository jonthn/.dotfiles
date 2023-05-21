#!/bin/sh

_shell_currenthost=$(ulimit -c 0;hostname 2>&-)

# Host Sweet Home
export HSH="${HOME}/._/${_shell_currenthost}"
test -d "${HSH}" || install -d "${HSH}"

if [ -z "${XDG_CONFIG_HOME-}" -a -d "${HSH}/.config" ]; then
	export XDG_CONFIG_HOME="${HSH}/.config"
else
	export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
fi

if [ -z "${XDG_CACHE_HOME-}" -a -d "${HSH}/.cache" ]; then
	export XDG_CACHE_HOME="${HSH}/.cache"
else
	export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
fi

if [ -z "${XDG_DATA_HOME-}" -a -d "${HSH}/.local/share" ]; then
	export XDG_DATA_HOME="${HSH}/.local/share"
else
	export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
fi

if [ -z "${XDG_STATE_HOME-}" -a -d "${HSH}/.local/state" ]; then
	export XDG_STATE_HOME="${HSH}/.local/state"
else
	export XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"
fi


_base_configshell="${XDG_CONFIG_HOME}/shell"
_base_cacheshell="${XDG_CACHE_HOME}/shell"
_base_localprefix="$(CDPATH='' cd -- "${XDG_DATA_HOME}/.." >/dev/null 2>&1 && pwd -P)"

# Which shell and environment {{{

__shell() {

	if [ ! -z "$ZSH_VERSION" ]; then
		shell_detected=zsh
	elif [ ! -z "$BASH_VERSION" ]; then
		shell_detected=bash
	elif [ ! -z "$KSH_VERSION" ]; then
		if [ "${KSH_VERSION/MIRBSD KSH}" != "$KSH_VERSION" ]; then
			shell_detected=mksh
		fi
	else
		shell_detected=posix
	fi

	printf '%s' $shell_detected
	return 0
}

__utfenv() {
	case "$LANG $CHARSET $LANGUAGE $LC_CTYPE" in
		(*utf*) return 0
			;;
		(*UTF*) return 0
			;;
		(*) return 1
			;;
	esac
}

# }}}

# Logging and output {{{

_logging()
{
	[ ! -d "${XDG_STATE_HOME}/log/shell" ] && install -d "${XDG_STATE_HOME}/log/shell"
	export SHELL_LOG="${XDG_STATE_HOME}/log/shell/$(date +%Y-%m-%d-%s).log"
	touch "${SHELL_LOG}"

	find "${XDG_STATE_HOME}/log/shell" \
		-mtime +10\
		-exec rm {} \;
}

# }}}

# Log XDG set {{{
_shell_XDG()
{
	_inform 'XDG_CONFIG_HOME  :  %s\n' "${XDG_CONFIG_HOME}"
	_inform 'XDG_CACHE_HOME   :  %s\n' "${XDG_CACHE_HOME}"
	_inform 'XDG_DATA_HOME    :  %s\n' "${XDG_DATA_HOME}"
	_inform 'XDG_STATE_HOME   :  %s\n' "${XDG_STATE_HOME}"
}
# }}}

# vim: set ft=sh ts=8 noet :
