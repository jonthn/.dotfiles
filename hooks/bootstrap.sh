#!/bin/sh

basedir=$(CDPATH='' cd -- "$(dirname -- "${0}")" 2>/dev/null; pwd -P 2>/dev/null)

. "${basedir}/../tag-shell/local/share/shell/helpers.sh"

if ! command -v rcup >/dev/null 2>&1; then
	_temp_local_bin_path=$(CDPATH='' cd -- "${basedir}/../local/bin" >/dev/null 2>&1; pwd -P 2>/dev/null)
	_temp_local_man_path=$(CDPATH='' cd -- "${basedir}/../local/man" >/dev/null 2>&1; pwd -P 2>/dev/null)
	PATH=$(modify_colon_var "$PATH" "${_temp_local_bin_path}" pre)
	MANPATH=$(modify_colon_var "$MANPATH" "${_temp_local_man_path}" post)
	printf 'Change you env with :\nexport PATH="%s"\nexport MANPATH="%s"\n\n' "$PATH" "$MANPATH"
	unset _temp_local_bin_path
	unset _temp_local_man_path
fi

available_tags=$(find "$basedir/../" -type d -name "tag-*" | sed s,^.*tag-,*\ ,)

printf "After updating your PATH you may use 'rcup'"
printf " with any combination of those tags : \\n%s" "$available_tags"
printf "\\n"
printf "Example: rcup -t git -t vim\\n"
