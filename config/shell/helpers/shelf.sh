##
# shelf functions are added features to the shell operations to help proceed
#  with some setup or everyday tasks.
# They are convenient functions
#

_shelf_inners_list()
{
	typeset -f | awk '/^[^ {}]+ *\(\)/ { gsub(/[()]/, "", $1); print $1}' | grep ^shf_
}

_shelf_list()
{
	local found
	if [ $# -eq 0 ]; then
		printf "[shelf] Available commands :\n"
	fi

	_shelf_inners_list |
		sed -e 's,shf_\([^_]*\)_.*,\1,'|
		uniq
}

shelf()
{
	local help=false
	if [ $# -eq 0 ] || ( [ $# -eq 1 ] && [ list = "${1}" ] ) ; then
		_shelf_list
		return 0
	fi
}

# Load inner (~add-ons) 'inner.*.sh' {{{

_shelf_load()
{
	local inner_dir=${1}

	[ ! -d "${inner_dir}" ] && return 0

	if [ "$(__shell)" = zsh ]; then
		setopt local_options nullglob
	fi

	for f in "${inner_dir}"/inner.*.sh;
	do
		[ ! -r "${f}" ] && continue
		_inform " loading shelf %s\n" "${f}"
		. "${f}" "$(dirname "${f}" 2>/dev/null)"
		_inform " loaded shelf %s\n" "${f}"
	done
}

# }}}

# vim: set ft=sh ts=8 noet :
