_innershelf_shell_fasd_update()
{
	latest_update_fasd=${XDG_CACHE_HOME:-${HOME}/.cache}/rcm/fasd.update

	if [ -r "${latest_update_fasd}" ] && [ "$(cat "${latest_update_fasd}")" -ge "$(date +%Y%m%d)" ]; then
		# no need to update
		return 0
	fi

	## fasd for shell
	printf 'Updating fasd ... \n'
	if command -v curl >/dev/null 2>&1; then
		curl -fkLo /tmp/$$.fasd https://raw.githubusercontent.com/clvv/fasd/master/fasd
	elif command -v wget >/dev/null 2>&1; then
		wget -O /tmp/$$.fasd https://raw.githubusercontent.com/clvv/fasd/master/fasd
	else
		printf "Can't download fasd script, abort update\n"
		return 1
	fi

	if [ -f /tmp/$$.fasd ]; then
		# remove init from fasd as we do it our way
		sed '/fasd --init env/q' /tmp/$$.fasd > ${XDG_DATA_HOME:-${HOME}/.local/share}/rcm/dotfiles/tag-shell/shell/add.fasd.sh
	fi
	if [ -f /tmp/$$.fasd ]; then
		rm /tmp/$$.fasd
	fi

	local dir_latest_update="$(dirname "${latest_update_fasd}")"
	[ ! -d "${dir_latest_update}" ] && install -d "${dir_latest_update}"
	date +%Y%m%d > "${latest_update_fasd}"

	true
}

_innershelf_shell_ShellCheck()
{
	local STACK_ROOT=${XDG_CACHE_HOME:-${HOME}/.cache}/stack

	if command -v curl >/dev/null 2>&1; then
		printf 'Installing/Updating ShellCheck ... \n'
		curl -sSL https://get.haskellstack.org/ | STACK_ROOT="${STACK_ROOT}" sh -s - -f -d "${XDG_DATA_HOME:-${HOME}/.local/share}/../bin"

	elif command -v wget >/dev/null 2>&1; then
		wget -O - https://get.haskellstack.org/ | STACK_ROOT="${STACK_ROOT}" sh -s - -f -d "${XDG_DATA_HOME:-${HOME}/.local/share}/../bin"
	else
		printf "Could not download/update stack, aborting\n"
		return 1
	fi

	if command -v stack >/dev/null 2>&1; then
		STACK_ROOT="${STACK_ROOT}" stack --resolver lts-14.27 install ShellCheck
		STACK_ROOT="${STACK_ROOT}" stack purge
	elif [ -x "${XDG_DATA_HOME:-${HOME}/.local/share}/../bin"/stack ]; then
		STACK_ROOT="${STACK_ROOT}" "${XDG_DATA_HOME:-${HOME}/.local/share}/../bin"/stack --resolver lts-14.27 install ShellCheck
		STACK_ROOT="${STACK_ROOT}" "${XDG_DATA_HOME:-${HOME}/.local/share}/../bin"/stack purge
	else
		printf "Missing Stack, aborting\n"
		return 1
	fi
}


innershelf_shell()
{
	case "${1}" in
		keyword)
			printf "%s" "shell"
			return 0
			;;
		synopsis)
			printf "%s\n" "Shell related"
			return 0
			;;
		debug)
			;;
		reload)
			shelf_init
			initialize_shell
			;;
		fasd)
			_innershelf_shell_fasd_update
			;;
		shellcheck)
			_innershelf_shell_ShellCheck
			;;
		help|usage|*)
			printf "[%s] has\n" "$(innershelf_shell keyword)"
			printf "COMMANDS:\n"
			printf "%-25s# %s\n" "reload" "reload shell configuration"
			printf "%-25s# %s\n" "fasd" "update fasd (z command)"
			printf "%-25s# %s\n" "shellcheck" "install ShellCheck"
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

# vim: set ft=sh ts=8 noet :
