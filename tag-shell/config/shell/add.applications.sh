_innershelf_applications_env()
{
	apps_registered="${1}"
	action="${2}"
	local parsed_yml
	parsed_yml=$(mktemp -q)

	if [ ! -e "${apps_registered}" ]; then
		return 0
	fi

	yaml_parse "${apps_registered}" > "${parsed_yml}"

	local new_path >/dev/null
	local new_clear_path >/dev/null

	new_path="${PATH}"
	new_clear_path="${PATH}"

	local restart_point=''
	local item_=''
	while item_=$(yaml_getl "${parsed_yml}" applications__ name "${restart_point}" apps_info_); do
		local go_on=true
		eval "$(printf "%s\n" "${item_}" | yaml_local_variables)" >/dev/null
		eval "${item_}"
		restart_point=$(printf "%s\n" "${item_}" | tail -n1)

		if [ '#' = "$(printf "%s" "${restart_point}" | cut -c1)" ]; then
			restart_point="$( printf "%s" "${restart_point}" | cut -c2-)"
		else
			go_on=false
		fi

		new_path=$(modify_colon_var "${new_path}" "${apps_info_path}" pre)
		new_clear_path=$(modify_colon_var "${new_clear_path}" "${apps_info_path}" remove)

		eval "$(printf "%s\n" "${item_}" | yaml_unset_variables)" >/dev/null
		if ! ${go_on}; then
			break
		elif ! ${operation_res}; then
			if ! "${option_continue}"; then
				break;
			fi
		fi
	done

	case "${action}" in
		show)
			printf "%s=%s\n"\
				PATH "${PATH}"

			;;
		set)
			printf "%s=%s\n"\
				PATH "${new_path}"

			;;
		use)
			export PATH="${new_path}"
			;;
		clear)
			export PATH="${new_clear_path}"
			;;
		*)
			printf "[%s env] has\n" "$(innershelf_applications keyword)"
			printf "COMMANDS:\n"
			printf "%-25s# %s\n" "set" "display the desired values (useful for eval())"
			printf "%-25s# %s\n" "show" "shows current value(s)"
			printf "%-25s# %s\n" "use" "export the values as shown in 'set'"
			printf "%-25s# %s\n" "clear" "'unset' the variable(s)"

			;;
	esac

}

innershelf_applications()
{
	local apps_registered_yml="${XDG_CACHE_HOME:-${HOME}/.cache}/applications/registered.yml"

	case "${1}" in
		keyword)
			printf "%s" "applications"
			return 0
			;;
		synopsis)
			printf "%s\n" "Manage (partly) applications in .local"
			return 0
			;;
		edit)
			if [ ! -e "${apps_registered_yml}" ]; then
				if [ ! -d "$(dirname "${apps_registered_yml}")" ]; then
					install -v -d "$(dirname "${apps_registered_yml}")"
				fi

				cat > "${apps_registered_yml}" <<-EOF
				---
				applications:
				#  -
				#    name: example
				#    path: $HOME/.local/applications/example/bin
				EOF
			fi

			$EDITOR "${apps_registered_yml}"
			;;
		env)
			shift
			_innershelf_applications_env "${apps_registered_yml}" "${@}"
			;;
		help|usage|*)
			printf "[%s] has\n" "$(innershelf_applications keyword)"
			printf "COMMANDS:\n"
			printf "%-25s# %s\n" "edit" "(un)register a new application path"
			printf "%-25s# %s\n" "env" "environment variables if you need (see env help for more)"
			case "${1}" in
				help|usage)
					return 0
					;;
				*)
					return 1
					;;
			esac
			;;
	esac
}
