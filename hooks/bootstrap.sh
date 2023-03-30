#!/bin/sh

no_rcup=false
basedir=$(CDPATH='' cd -- "$(dirname -- "${0}")" 2>/dev/null; pwd -P 2>/dev/null)

. "${basedir}/../tag-shell/config/shell/helpers/helpers.sh"
. "${basedir}/../tag-shell/config/shell/bases.sh"



if ! command -v rcup >/dev/null 2>&1; then
	no_rcup=true
	_temp_local_bin_path=$(CDPATH='' cd -- "${basedir}/../tag-rcm/local/bin" >/dev/null 2>&1; pwd -P 2>/dev/null)
	_temp_local_man_path=$(CDPATH='' cd -- "${basedir}/../tag-rcm/local/man" >/dev/null 2>&1; pwd -P 2>/dev/null)
	PATH=$(modify_colon_var "$PATH" "${_temp_local_bin_path}" pre)
	MANPATH=$(modify_colon_var "$MANPATH" "${_temp_local_man_path}" post)
	printf 'Change you env with :\nexport PATH="%s"\nexport MANPATH="%s"\n\n' "$PATH" "$MANPATH"
	unset _temp_local_bin_path
	unset _temp_local_man_path
	printf "After updating your PATH you may use 'rcup'"
fi

available_tags=$(find "$basedir/../" -type d -name "tag-*" | sed s,^.*tag-,*\ ,)

printf " 'rcup' with any combination of those tags : \\n%s" "$available_tags"
printf "\\n"
printf "Example: rcup -t git -t vim\\n"
printf "Recommendations:\n"
if ! "${no_rcup}"; then
	printf '\nexport PATH="%s"\nexport MANPATH="%s"\n' "$PATH" "$MANPATH"
fi
printf "install -v -d %q\n" "${XDG_CONFIG_HOME:-$HOME/.config}/rcm"
printf "%s > %q\n" 'printf "TAGS=\"rcm\"\n#HOSTNAME=xxx\n"' "${XDG_CONFIG_HOME:-$HOME/.config}/rcm/rcrc"
printf "RCRC=\"%s\" rcup -t rcm\\n" "${XDG_CONFIG_HOME:-$HOME/.config}/rcm/rcrc"
