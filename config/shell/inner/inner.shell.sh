# Search in history {{{

shf_shell_h()
{
	if [ "-h" = "${1}" -o "--help" = "${1}" ] || [ $# = 0 ]; then
		printf 'usage: <args grep for history search>\n'
		return 1
	fi

	case $(__shell) in
		mksh|zsh)
			fc -l 0 | grep "$@"
			;;
		*)
			history | grep "$@"
			;;
	esac
}

# }}}

# Delete .DS_Store and __MACOSX directories {{{

shf_shell_remove_macos_cruft()
{
	if [ "-h" = "${1}" -o "--help" = "${1}" ]; then
		printf "usage: [dir]\n"\
			'\tremove .DS_Store and __MACOSX directories of '\
			'directory if specified or current dir otherwise\n'
		return 0
	fi

	find "${@:-$PWD}" \( \
		-type f -name '.DS_Store' -o \
		-type d -name '__MACOSX' \
		\) -print0 | xargs -0 rm -rf
}

# }}}

shf_shell_zoxide()
{
	local help=false
	local zoxide_update
	local zoxide_location
	zoxide_update="${XDG_CACHE_HOME}/zoxide/zoxide.update"
	zoxide_location="${_base_localprefix}/bin/zoxide"

	if [ "-h" = "${1}" -o "--help" = "${1}" ]; then
		printf "Install/update zoxide in '%s'\n" "${zoxide_location}"
		help=true
	fi

	if [ $# -eq 2 -a location = "${1}" ]; then
		printf "%s" "${zoxide_location}"
		return 0
	fi

	if [ -x "${zoxide_location}" ] && [ -r "${zoxide_update}" ]; then

		if [ "$(cat "${zoxide_update}")" -ge "$(date +%Y%m%d)" ]; then
			if ${help}; then
				printf "\tskip update zoxide\n"
			fi
			# no need to update
			return 0
		fi
	fi

	## zoxide for shell
	if [ ! -x "${zoxide_location}" ]; then
		_inform 'Installing zoxide ... \n'
	else
		_inform 'Updating zoxide ... \n'
	fi

	local platform
	platform=''

	case "$(uname -s)" in
		Linux)
			case "$(uname -m)" in
				x86_64 | x86-64 | amd64)
					platform=x86_64-unknown-linux-musl
					;;
				*)
					;;
			esac
			;;
		Darwin)
			case "$(uname -m)" in
				x86_64 | x86-64 | amd64)
					platform=x86_64-apple-darwin
					;;
				*)
					;;
			esac
			;;
		*)
			;;
	esac

	local dir_latest_update="$(dirname "${zoxide_update}")"
	[ ! -d "${dir_latest_update}" ] && install -d "${dir_latest_update}"

	if [ -z "${platform}" ]; then
		printf "2999-99-99" > "${zoxide_update}"
		_fault "Use Rust/cargo to install zoxide\n"
		return 1
	fi

	local dl_url
	dl_url=

	if command -v curl >/dev/null 2>&1; then
		dl_url=$(curl -s https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest | grep "browser_download_url" | cut -d '"' -f 4 | grep "${platform}")
		curl -fkLo /tmp/$$.zoxide "${dl_url}"
	elif command -v wget >/dev/null 2>&1; then
		dl_url=$(wget -q -O - https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest | grep "browser_download_url" | cut -d '"' -f 4 | grep "${platform}")
		wget -O /tmp/$$.zoxide "${dl_url}"
	else
		_fault "Can't download zoxide (%s), abort update\n" "${dl_url}"
		return 1
	fi

	if [ -f /tmp/$$.zoxide ]; then
		install -d -v "$(dirname "${zoxide_location}")"
		install -d -v "$(dirname "${zoxide_location}")/../man/man1"
		tar xf /tmp/$$.zoxide -C "$(dirname "${zoxide_location}")" zoxide
		tar xf /tmp/$$.zoxide -C "$(dirname "${zoxide_location}")/../man/" man
	fi
	if [ -f /tmp/$$.zoxide ]; then
		rm -f /tmp/$$.zoxide
		rm -f /tmp/$$.zoxide.bak
	fi

	date +%Y%m%d > "${zoxide_update}"

	true
}

shf_shell_ShellCheck()
{
	local STACK_ROOT
	STACK_ROOT="${XDG_CACHE_HOME}/ShellCheck"
	local destination_bin
	destination_bin="${_base_localprefix}/bin"

	if [ "-h" = "${1}" -o "--help" = "${1}" ]; then
		printf "Install/update ShellCheck in '%s'\n" "${destination_bin}"
		help=true
	fi

	if command -v stack >/dev/null 2>&1; then
		STACK_ROOT="${STACK_ROOT}" stack --resolver lts --local-bin-path "${destination_bin}" install ShellCheck
		STACK_ROOT="${STACK_ROOT}" stack purge
	else
		install -vd "${STACK_ROOT}/.stack.local"
		_inform 'Installing/Updating ShellCheck ... \n'
		if command -v curl >/dev/null 2>&1; then
			curl -sSL https://get.haskellstack.org/ | STACK_ROOT="${STACK_ROOT}" sh -s - -f -d "${STACK_ROOT}/.stack.local"
		elif command -v wget >/dev/null 2>&1; then
			wget -O - https://get.haskellstack.org/ | STACK_ROOT="${STACK_ROOT}" sh -s - -f -d "${STACK_ROOT}/.stack.local"
		else
			_fault "Could not download/update stack, aborting\n"
			return 1
		fi

		STACK_ROOT="${STACK_ROOT}" "${STACK_ROOT}/.stack.local"/stack --resolver lts --local-bin-path "${destination_bin}" install ShellCheck
		STACK_ROOT="${STACK_ROOT}" "${STACK_ROOT}/.stack.local"/stack purge
	fi
}

shf_shell_reload()
{
	source "${XDG_CONFIG_HOME}/shell/configuration.sh"
}

# Create 'Host' XDG {{{
shf_shell_makehost_XDG() {

	install -v -d "${HOME}/._/${_shell_currenthost}/config"
	install -v -d "${HOME}/._/${_shell_currenthost}/cache"
	install -v -d "${HOME}/._/${_shell_currenthost}/share"
	install -v -d "${HOME}/._/${_shell_currenthost}/state"
}
# }}}


# vim: set ft=sh ts=8 noet :
