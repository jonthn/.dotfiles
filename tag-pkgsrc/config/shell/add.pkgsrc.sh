_innershelf_pkgsrc_env()
{
	case "${1}" in
		pkgsrc)
			local pkgsrc="${XDG_CACHE_HOME:-${HOME}/.cache}/pkgsrc"

			printf "%s" "${pkgsrc}"
			;;
		pkgdist)
			local pkgdist=$(CDPATH='' cd -- "${XDG_DATA_HOME:-${HOME}/.local/share}/.." >/dev/null 2>&1; pwd -P 2>/dev/null)
			pkgdist="${pkgdist}/applications/pkg"

			printf "%s" "${pkgdist}"
			;;
		*)
			;;
	esac
}

_innershelf_pkgsrc_sources()
{
	local pkgsrc="$(_innershelf_pkgsrc_env pkgsrc)"

	printf "pkgsrc setup in '%s'... \n" "$pkgsrc"

	if [ -d "${pkgsrc}" ]; then
		>&2 printf "pkgsrc already exists (%s)\n" "${pkgsrc}"
		return 0
	fi

	install -d -v "${pkgsrc}"

	if command -v git >/dev/null 2>&1; then
		git clone --config branch.autosetuprebase=always https://github.com/NetBSD/pkgsrc "${pkgsrc}" && \
			git clone --config branch.autosetuprebase=always git://wip.pkgsrc.org/pkgsrc-wip.git "${pkgsrc}/wip"
	else
		if command -v curl >/dev/null 2>&1; then
			curl -fkLo /tmp/$$.pkgsrc.tar.gz http://ftp.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz
			curl -fkLo /tmp/$$.pkgsrc-wip.tar.gz "https://wip.pkgsrc.org/cgi-bin/gitweb.cgi?p=pkgsrc-wip.git;a=snapshot;h=HEAD;sf=tgz"
		elif command -v wget >/dev/null 2>&1; then
			wget -O /tmp/$$.pkgsrc.tar.gz http://ftp.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz
			wget -O /tmp/$$.pkgsrc-wip.tar.gz "https://wip.pkgsrc.org/cgi-bin/gitweb.cgi?p=pkgsrc-wip.git;a=snapshot;h=HEAD;sf=tgz"
		else
			>&2 printf "Can't download pkgsrc sources\n"
			return 2
		fi

		rm -rf /tmp/pkgsrc.tree
		mkdir /tmp/pkgsrc.tree
		tar -C /tmp/pkgsrc.tree -xf /tmp/$$.pkgsrc.tar.gz --strip-components 1
		tar -C /tmp/pkgsrc.tree -xf /tmp/$$.pkgsrc-wip.tar.gz
		rsync -a --delete /tmp/pkgsrc.tree/* "${pkgsrc}"

		rm -f /tmp/$$.pkgsrc-wip.tar.gz
		rm -f /tmp/$$.pkgsrc.tar.gz
		rm -rf /tmp/pkgsrc.tree
	fi
}

_innershelf_pkgsrc_bootstrap()
{
	local pkgsrc="$(_innershelf_pkgsrc_env pkgsrc)"
	local pkgdist="$(_innershelf_pkgsrc_env pkgdist)"

	printf "pkgsrc bootstrap in '%s' based on '%s'... \n" "${pkgdist}" "${pkgsrc}"

	if [ -d "${pkgsrc}/bootstrap/work" ]; then
		rm -rf "${pkgsrc}/bootstrap/work"
	fi

	local bootstraptmp=$(mktemp -q)

	pkgsrc_fragment=""
	if [ -r "${XDG_DATA_HOME:-${HOME}/.local/share}/pkgsrc/pkgsrc.fragment.mk" ]; then
		pkgsrc_fragment="${XDG_DATA_HOME:-${HOME}/.local/share}/pkgsrc/pkgsrc.fragment.mk"
	fi

	# Change sh_shell for bash on Linux
	SH_SHELL=$(command -v sh)
	if [ "$(uname -s 2>/dev/null)" = "Linux" ]; then
		SH_SHELL=$(command -v bash)
	fi

	if ! (cd "${pkgsrc}/bootstrap/" && \
		printf "%s %s\n" "./bootstrap ${pkgsrc_fragment:+--mk-fragment ${pkgsrc_fragment}}\
			--unprivileged --prefix" "${pkgdist}"
		SH=$SH_SHELL ./bootstrap ${pkgsrc_fragment:+--mk-fragment ${pkgsrc_fragment}}\
		--unprivileged --prefix "${pkgdist}" >${bootstraptmp} 2>&1); then
		printf "pkgsrc bootstrap failed (see %s)\n" "${bootstraptmp}"
	else
		printf "pkgsrc bootstrap complete\n"
	fi
}

_innershelf_pkgsrc_packages()
{
	local operation='help'
	local option_continue=false
	local packages=''

	while [ $# -gt 0 ];
	do
		case "$1" in
			-continue)
				option_continue=true
				shift
				;;
			list)
				operation='list'
				shift
				;;
			install)
				operation='install'
				shift
				;;
			update)
				operation='update'
				shift
				;;
			*)
				if [ -r "${1}" ]; then
					packages="${1}"
				elif [ -r "${XDG_DATA_HOME:-${HOME}/.local/share}/pkgsrc/packages.${1}.yml" ]; then
					packages="${XDG_DATA_HOME:-${HOME}/.local/share}/pkgsrc/packages.${1}.yml"
				else
					>&2 printf "Unknown option '%s'" "$1"
				fi
				shift
				;;
		esac
	done

	case ${operation} in
		help)
			printf "[%s packages] has\n" "$(innershelf_pkgsrc keyword)"
			printf "COMMANDS:\n"
			printf "%-25s# %s\n" "install <set>" "install this set of programs"
			printf "%-25s# %s\n" "\t[-continue]" "continue the operation even if one package fails"
			printf "%-25s# %s\n" "list [set]" "list the programs in this set or sets available"
			printf "%-25s# %s\n" "update" "update the programs installed"
			printf "%-25s# %s\n" "\t[-continue]" "continue the operation even if one package fails"
			;;
		install)
			if [ -z "${packages}" ]; then
				>&2 printf "No packages file provided\n"
				return 2
			fi
			;;
	esac

	local pkgsrc="$(_innershelf_pkgsrc_env pkgsrc)"
	local pkgdist="$(_innershelf_pkgsrc_env pkgdist)"
	local failed_packages=""
	local success_packages=""

	case ${operation} in
		install)
			printf "Install from %s\n" "$(basename "${packages}")"
			;;
		list)
			if [ -z "${packages}" ]; then
				local available_sets=$(find "${XDG_DATA_HOME:-${HOME}/.local/share}/pkgsrc/" -name "packages.*.yml" | sed 's,^.*packages\.\(.*\)\.yml,\1,')
				printf "Packages available\n%s\n" "${available_sets}"
				return 0
			else
				printf "Package(s) in %s\n"  "$(basename "${packages}")"
			fi

			;;
	esac

	parsed_yml=$(mktemp -q)

	yaml_parse "${packages}" > "${parsed_yml}"

	local restart_point=''
	local item_=''
	while item_=$(yaml_getl "${parsed_yml}" packages__ name "${restart_point}" pkgsrc_p_); do
		local go_on=true
		eval "$(printf "%s\n" "${item_}" | yaml_local_variables)" >/dev/null
		eval "${item_}"
		restart_point=$(printf "%s\n" "${item_}" | tail -n1)

		if [ '#' = "$(printf "%s" "${restart_point}" | cut -c1)" ]; then
			restart_point="$( printf "%s" "${restart_point}" | cut -c2-)"
		else
			go_on=false
		fi

		local operation_res=true
		case ${operation} in
			install)
				printf "Package %s ... " "${pkgsrc_p_name}"

				if pkg_info -E "$(bmake -C "${pkgsrc}/${pkgsrc_p_dir}" show-var VARNAME=PKGNAME)" >/dev/null 2>&1; then
					printf "Already installed, skipping\n"
				else
					local bmake_output="$(mktemp -q)"
					if ! bmake -C "${pkgsrc}/${pkgsrc_p_dir}" install clean clean-depends >"${bmake_output}" 2>&1; then
						operation_res=false
						printerr "Failed\n"
						cat "${bmake_output}"
					else
						printf " [done] \n"
					fi
					rm -f "${bmake_output}"
				fi
				;;
			list)
				printf "%s\n" "${pkgsrc_p_name}"
				;;
		esac

		eval "$(printf "%s\n" "${item_}" | yaml_unset_variables)" >/dev/null
		if ! ${go_on}; then
			break
		elif ! ${operation_res}; then
			if ! "${option_continue}"; then
				break;
			fi
		fi
	done
}

innershelf_pkgsrc()
{
	case "${1}" in
		keyword)
			printf "%s" "pkg"
			return 0
			;;
		synopsis)
			printf "%s\n" "pkgsrc distribution"
			return 0
			;;
		debug)
			;;
		setup)
			if _innershelf_pkgsrc_sources; then
				_innershelf_pkgsrc_bootstrap
			fi
			;;
		dismantle)
			local pkgsrc="$(_innershelf_pkgsrc_env pkgsrc)"
			local pkgdist="$(_innershelf_pkgsrc_env pkgdist)"

			rm -ir "${pkgsrc}"
			rm -ir "${pkgdist}"
			;;
		env)
			local pkgdist="$(_innershelf_pkgsrc_env pkgdist)"
			shift

			local new_path >/dev/null
			local new_manpath >/dev/null
			local pkgpathbin >/dev/null
			local pkgpathsbin >/dev/null
			local pkgmanpath >/dev/null
			new_path="${PATH}"
			new_manpath="${MANPATH:-:}"

			pkgpathbin="${pkgdist}/bin"
			pkgpathsbin="${pkgdist}/sbin"
			pkgmanpath="${pkgdist}/man"

			new_path=$(modify_colon_var "${new_path}" "${pkgpathbin}" pre)
			new_path=$(modify_colon_var "${new_path}" "${pkgpathsbin}" post)
			new_manpath=$(modify_colon_var "${new_manpath}" "${pkgmanpath}" post)

			case "${1}" in
				show)
					printf "%s=%s\n%s=%s\n"\
						PATH    "${PATH}"\
						MANPATH "${MANPATH}"
					;;
				set)
					printf "%s=%s\n%s=%s\n"\
						PATH     "${new_path}"\
						MANPATH  "${new_manpath}"
					;;
				use)
					export PATH="${new_path}"
					export MANPATH="${new_manpath}"
					;;
				clear)
					new_path=$(modify_colon_var "${new_path}" "${pkgpathbin}" remove)
					new_path=$(modify_colon_var "${new_path}" "${pkgpathsbin}" remove)
					new_manpath=$(modify_colon_var "${new_manpath}" "${pkgmanpath}" remove)
					new_manpath=${new_manpath:+:}${new_manpath}

					export PATH="${new_path}"
					if [ -z "${new_manpath}" ]; then
						unset MANPATH
					else
						export MANPATH="${new_manpath}"
					fi
					;;
				*)
					printf "[%s env] has\n" "$(innershelf_pkgsrc keyword)"
					printf "COMMANDS:\n"
					printf "%-25s# %s\n" "set" "display the desired values (useful for eval())"
					printf "%-25s# %s\n" "show" "shows current value(s)"
					printf "%-25s# %s\n" "use" "export the values as shown in 'set'"
					printf "%-25s# %s\n" "clear" "'unset' the variable(s)"
					;;
			esac
			;;
		clean)
			local pkgsrc="$(_innershelf_pkgsrc_env pkgsrc)"

			printf "removing work directories ...\n"
			find "${pkgsrc}" -name work -exec rm -rf {} +
			printf "done\n"
			;;
		list|install|update)
			_innershelf_pkgsrc_packages "${@}"
			;;
		help|usage|*)
			printf "[%s] has\n" "$(innershelf_pkgsrc keyword)"
			printf "COMMANDS:\n"
			printf "%-25s# %s\n" "setup" "install pkgsrc and bootstrap"
			printf "%-25s# %s\n" "dismantle" "remove pkgsrc"
			printf "%-25s# %s\n" "env" "environment variables (see env help)"
			printf "%-25s# %s\n" "clean" "remove 'workdir' for pkgsrc"
			printf "%-25s# %s\n" "list" "packages to install/list (see packages help)"
			printf "%-25s# %s\n" "install" "packages to install/list (see packages help)"
			printf "%-25s# %s\n" "update" "packages to install/list (see packages help)"
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
