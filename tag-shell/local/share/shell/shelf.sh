##
# innershelf_xxx()
#
# should respond to
#  help
#  usage (can be an alias of help)
#  keyword
#  synopsis
#  debug
#  ... any action you want to list
#  (setup) if some actions needs to be taken such as getting something online
#  (dismantle) removing all those local files
#  (update) 'update' the setup above

# innershelf_example()
# {
# 	local debug=false
#
# 	case ${1} in
# 		help|usage)
# 			printf "help\n"
# 			return 0
# 			;;
# 		keyword)
# 			printf "%s" "example"
# 			return 0
# 			;;
# 		synopsis)
# 			printf "%s\n" "example command is just an example"
# 			return 0
# 			;;
# 		debug)
# 			debug=true
# 			;;
# 		*)
# 			printf "Please specify an action, see 'help'\n"
# 			return 1
# 			;;
# 	esac
#
# 	printf "Example doing something\n"
# }

_shelf_inners_list()
{
	typeset -f | awk '/^[^ {}]+ *\(\)/ { gsub(/[()]/, "", $1); print $1}' | grep ^innershelf_
}

_shelf_list()
{
	local found=false
	local raw=false
	if [ $# -eq 0 ]; then
		printf "[shelf] Available commands :\n"
		found=true
	elif [ "--raw" = "${1}" ]; then
		found=true
		raw=true
	fi

	local listf=$(mktemp -q)


	_shelf_inners_list > "${listf}"

	while read -r cmdfunc
	do
		if ${found}; then
			local kw_str="$(${cmdfunc} keyword)"
			local descr_str="$(${cmdfunc} synopsis)"
			if ${raw}; then
				printf -- '%s\n' "${kw_str}"
			else
				printf -- '- %-25s%s%s\n' "${kw_str}" "${descr_str:+"# "}" "${descr_str}"
			fi
		elif [ "${1}" = "$(${cmdfunc} keyword)" ]; then
			# find function providing keyword in argument
			printf '%s\n' "${cmdfunc}"
			found=true
			break
		fi
	done < "${listf}"
	rm -f "${listf}"

	${found}
}

shelf()
{
	local help=false
	if [ $# -eq 0 ] || ( [ $# -eq 1 ] && [ help = "${1}" ] ) ; then
		printf 'usage : shelf <cmd> [option ..]\n'
		printf '\n'
		printf 'COMMANDS:\n'
		printf ' list              will list all available commands\n'
		printf ' help <subcommand> get help for this subcommand\n'
		return 0
	elif [ help = "${1}" ]; then
		help=true
		shift
	elif [ list = "${1}" ]; then
		shift
		_shelf_list "${@}"
		return 0
	fi

	# find innershelf providing this feature/command a.k.a keyword
	if func=$(_shelf_list "${1}"); then
		shift
		if ${help}; then
			"${func}" help "${@}"
		else
			"${func}" "${@}"
		fi
	else
		printerr "Command '%s' not found\n" "${1}"
		false
	fi
}

# vim: set ft=sh ts=8 noet :
