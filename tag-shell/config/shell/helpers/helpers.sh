## Modify var ($1) to add element if the argument isn't already in it
#
# arg1 var content to modify
# arg2 element to include
# arg3 (option) which determines the position or action regarding the element
#        "pre"    insert at beginning
#        "post"   insert at the end
#        "remove" remove it from the variable
#        by default it will be post
#
# return 0 no modification required
#        1 modification done
#        2 in case of error
modify_colon_var()
{
	pos="post"
	case $# in
		2)
			;;
		3)
			pos="$3"
			;;
		*)
			printf '%s' "$1"
			return 2
	esac

	if [ -z "$1" ]; then
		printf '%s' "$2"
		return 1
	fi

	case ":${1:=$2}:" in
		*:$2:*)
			ret=0
			case "${pos}" in
				remove)
					printf '%s' "$(printf "%s" "${1}" | sed -E -e "s,${2},,g" -e 's,:$,,' -e 's,^:,,' -e 's,:+,:,g')"
					ret=1
					;;
				*)
					printf '%s' "$1"
					;;
			esac
			return ${ret}
			;;
		*)
			case "${pos}" in
				pre)
					printf '%s:%s' "$2" "$1"
					;;
				post)
					printf '%s:%s' "$1" "$2"
					;;
				remove)
					# does not exist in $1
					printf '%s' "$1"
					;;
				*)
					_fault "Unknown operation %s\n" "${pos}"
					printf '%s' "$1"
					;;
			esac
			return 1
			;;
	esac;
}

# Find the given folder at the higher level in hierarchy
#
dirfind_top_in_hierarchy()
{
	[ 1 = $# ] || return 1

	look_for=$1
	[ -z "$look_for" ] && return 1

	local curr=. prev=

	while [ -d "$curr/$look_for" ]; do
		prev="$curr"
		curr+=/..

		if [ "$(cd "$prev" 2>/dev/null && pwd 2>/dev/null)" = / ]; then
			break
		fi
	done

	[ -z "$prev" ] && return 1

	([ ! -z "$prev" ] && [ -d "$prev/$look_for" ]) && printf '%s' "$(cd "$prev" 2>/dev/null && pwd 2>/dev/null)"
	return 0
}

## Find the given folder in the hierarchy folders but
#   but closer to the starting point
#
dirfind_in_hierarchy()
{
	[ 1 = $# ] || return 1

	look_for=$1
	[ -z "$look_for" ] && return 1

	curr=.
	while [ ! -d "$curr/$look_for" ]; do
		curr+=/..

		if [ "$(cd "$curr" 2>/dev/null && pwd 2>/dev/null)" = / ]; then
			break
		fi
	done

	if [ -d "$curr/$look_for" ]; then
		printf '%s' "$(cd "$curr" 2>/dev/null && pwd 2>/dev/null)"
		return 0
	else
		return 1
	fi
}

_fault()
{
	local fmt
	fmt="${1}"
	shift
	>&2 printf "%s {E} ${fmt}" "$(date +%Y-%m-%dT%H:%M:%S)" "${@}"
}

_warn()
{
	local fmt
	fmt="${1}"
	shift
	printf "%s {W} ${fmt}" "$(date +%Y-%m-%dT%H:%M:%S)" "${@}"
}

_inform()
{
	local fmt
	fmt="${1}"
	shift
	printf "%s {I} ${fmt}" "$(date +%Y-%m-%dT%H:%M:%S)" "${@}"
}

# vim: set ft=sh ts=8 noet :
