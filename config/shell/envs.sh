#!/bin/sh

SHELL_ORIGINAL_PATH="${SHELL_ORIGINAL_PATH:-${PATH}}"
SHELL_ORIGINAL_MANPATH="${SHELL_ORIGINAL_MANPATH:-${MANPATH}}"

if [ -z "${_base_configshell}" ]; then
	. "${XDG_CONFIG_HOME:-${HOME}/.config}"/shell/bases.sh
fi

ENVS="${XDG_CONFIG_HOME}/shell/env"

_shell_envs()
{
	local safe_path="${SHELL_ORIGINAL_PATH:-${PATH}}"

	_inform "PATH (before env) : %s\n" "${SHELL_ORIGINAL_PATH}"
	_inform "MANPATH (before env) : %s\n" "${SHELL_ORIGINAL_MANPATH}"
	_inform "Loading envs from %s\n" "${envs_dir}"

	for env_directives in "${ENVS}"/env.??.*.sh
	do
		_inform "Before %s PATH %s\n" "${env_directives}" "${PATH}"
		. "${env_directives}"
		if [ -z "${PATH}" ] || [ "${PATH}" != "${safe_path}" -a "${PATH}" = "${PATH#*${safe_path}}" ]; then
			local PATH_error="${PATH}"
			export PATH="${safe_path}"
			_fault "%s set PATH wrongly, safeguard activated, ignoring this change '%s'\n"\
				"${env_directives#${envs_dir}/}" "${PATH_error}"
		else
			safe_path="${PATH}"
		fi
		_inform "After  %s PATH %s\n" "${env_directives}" "${PATH}"
	done

	[ "${MANPATH:0:1}" != ":" ] && export MANPATH="${MANPATH:+:${MANPATH}}"

	_inform "PATH (after env) : %s\n" "${PATH}"
	_inform "MANPATH (after env) : %s\n" "${MANPATH}"
}

envs()
{
	cd $ENVS
}

# vim: set ft=sh ts=8 noet :
