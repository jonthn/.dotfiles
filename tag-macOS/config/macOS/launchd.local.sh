#!/bin/sh

_base_configshell="${XDG_CONFIG_HOME:-${HOME}/.config}/shell"

# Load add-ons 'add.*.sh' {{{

load_addons()
{
	local addons_dir=${1:-${_base_configshell}}

	for f in "${addons_dir}"/add.*.sh;
	do
		. $f $(dirname "${f}" 2>/dev/null);
	done
}

# }}}

load_addons "${_base_configshell}"

launchctl setenv PATH "${PATH}"
