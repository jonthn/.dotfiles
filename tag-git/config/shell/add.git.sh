_innershelf_gitwtf_update()
{
	printf 'Updating git wtf ...\n'
	local temp_gitwtf
	temp_gitwtf="$(mktemp -q)"
	if command -v curl >/dev/null 2>&1; then
		curl -fkLo "${temp_gitwtf}" https://raw.githubusercontent.com/bsedat/git-wtf/master/git-wtf
	elif command -v wget >/dev/null 2>&1; then
		wget -O "${temp_gitwtf}" https://raw.githubusercontent.com/bsedat/git-wtf/master/git-wtf
	else
		printerr "Can't download git wtf script, cancelling update"
		return 1
	fi

	if [ -f "${temp_gitwtf}" ] && [ -d "${XDG_DATA_HOME:-${HOME}/.local/share}/../bin" ]; then
		install -v -m 0755 "${temp_gitwtf}" "${XDG_DATA_HOME:-${HOME}/.local/share}/../bin/wtf-git"
		printf "git-wtf script has been updated\n"
	fi

	rm "${temp_gitwtf}"
}

innershelf_git()
{
	case "${1}" in
		keyword)
			printf "%s" "git"
			return 0
			;;
		synopsis)
			printf "%s\n" "Everything Git related"
			return 0
			;;
		debug)
			;;
		update-gitwtf)
			_innershelf_gitwtf_update
			;;
		help|usage|*)
			printf "[%s] has\n" "$(innershelf_git keyword)"
			printf "COMMANDS:\n"
			printf "%-25s# %s\n" "update-gitwtf" "update 'git-wtf' script"
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
