## printf to stderr
#
printerr()
{
	>&2 printf "${@}"
}

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
					>&2 printf "Unknown operation %s" "${pos}"
					printf '%s' "$1"
					;;
			esac
			return 1
			;;
	esac;
}

# vim: set ft=sh ts=8 noet :
