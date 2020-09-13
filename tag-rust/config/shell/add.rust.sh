_innershelf_rust_env()
{
	case "${1}" in
		rustup)
			local rustupbase="${XDG_CACHE_HOME:-${HOME}/.cache}/rustup"

			printf "%s" "${RUSTUP_HOME:-${rustupbase}}"
			;;
		cargo)
			# local cargobase="$(CDPATH='' cd -- "${XDG_DATA_HOME:-${HOME}/.local/share}/.." >/dev/null 2>&1; pwd -P 2>/dev/null)/cargo"
			local cargobase="${XDG_CACHE_HOME:-${HOME}/.cache}/cargo"

			printf "%s" "${CARGO_HOME:-${cargobase}}"
			;;
		cargobin)
			printf "%s" "$(_innershelf_rust_env cargo)"/bin
			;;
		cargo_installroot)
			local homeroot=$(CDPATH='' cd -- "${XDG_DATA_HOME:-${HOME}/.local/share}/.." >/dev/null 2>&1; pwd -P 2>/dev/null)
			homeroot="${homeroot}/applications/cargo"

			printf "%s" "${CARGO_INSTALL_ROOT:-${homeroot}}"
			;;
		*)
			;;
	esac
}

_innershelf_rust_bootstrap()
{
	local rustupbase="$(_innershelf_rust_env rustup)"
	local cargobase="$(_innershelf_rust_env cargo)"
	local latest_update_rustup=${XDG_CACHE_HOME:-${HOME}/.cache}/rustup/latest.rustupinit.update

	if [ ! -r "${latest_update_rustup}" ] || [ -r "${latest_update_rustup}" -a "$(cat "${latest_update_rustup}")" -lt "$(date +%Y%m%d)" ]; then
		local temp_rustup="$(mktemp -q)"
		printf 'Updating rustup.sh ... \n'
		if command -v curl >/dev/null 2>&1; then
			curl -fkLo "${temp_rustup}" https://sh.rustup.rs
		elif command -v wget >/dev/null 2>&1; then
			wget -O "${temp_rustup}" https://sh.rustup.rs
		else
			printerr "Can't update rustup script, using archived copy\n"
		fi

		[ ! -d "${rustupbase}/bin" ] && install -d "${rustupbase}/bin"
		if [ -f "${temp_rustup}" ] && [ -d "${rustupbase}/bin" ]; then
			install -m 0755 -v "${temp_rustup}" "${rustupbase}/bin/rustup-init"
			printf "rustup-init script has been updated\n"
		fi
		rm "${temp_rustup}"

		local dir_latest_update="$(dirname "${latest_update_rustup}")"
		[ ! -d "${dir_latest_update}" ] && install -d "${dir_latest_update}"
		date +%Y%m%d > "${latest_update_rustup}"
	fi

	if [ -x "${rustupbase}/bin/rustup-init" ]; then
		printf "rust bootstrap in '%s' (%s)... \n" "${cargobase}" "${rustupbase}"

		CARGO_HOME="${cargobase}" RUSTUP_HOME="${rustupbase}" "${rustupbase}/bin/rustup-init" --no-modify-path -y
		CARGO_HOME="${cargobase}" RUSTUP_HOME="${rustupbase}" ${CARGO_HOME}/bin/rustup default stable
	else
		printerr "Missing 'rustup-init' to install Rust"
		false
	fi
}

_innershelf_rust_selfup()
{
	local rustupbase="$(_innershelf_rust_env rustup)"
	local cargobase="$(_innershelf_rust_env cargo)"
	local cargobin="$(_innershelf_rust_env cargobin)"

	if command -v rustup >/dev/null 2>&1; then
		rustup self update
		rustup update
	elif [ -d "${rustupbase}" -a -d "${cargobase}" ]; then
		CARGO_HOME="${cargobase}" RUSTUP_HOME="${rustupbase}" ${cargobin}/bin/rustup self update
		CARGO_HOME="${cargobase}" RUSTUP_HOME="${rustupbase}" ${cargobin}/bin/rustup update
	else
		printerr "Missing 'rustup' to proceed with update"
		false
	fi
}

_innershelf_rust_packages()
{
	local cargobase="$(_innershelf_rust_env cargo)"
	local cargobin="$(_innershelf_rust_env cargobin)"
	local cargo_installroot="$(_innershelf_rust_env cargo_installroot)"

	case ${operation} in
		install)
			printf "Install from %s\n" "${set}"
			;;
		list)
			printf "Package(s) in %s\n" "${set}"
			;;
	esac

	parsed_yml=$(mktemp -q)

	yaml_parse "${packages}" > "${parsed_yml}"

	local restart_point=''
	local item_=''
	while item_=$(yaml_getl "${parsed_yml}" packages__ name "${restart_point}" rust_ils_); do
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
				local cmdinst=''
				if command -v cargo >/dev/null 2>&1; then
					cmdinst="cargo install ${rust_ils_args} ${rust_ils_name}"
				elif [ -x "${cargobin}/cargo" ]; then
					cmdinst="env CARGO_HOME="${cargobase}" CARGO_INSTALL_ROOT="${cargo_installroot}" ${cargobin}/cargo install ${rust_ils_args} ${rust_ils_name}"
				else
					printerr "Missing 'cargo' to install '%s'" "${rust_ils_name}"
				fi

				local cmd_output="$(mktemp -q)"
				printf "Package %s ... \n" "${rust_ils_name}"

				case $(__shell) in
					zsh)
						if ! ${=cmdinst} >"${cmd_output}" 2>&1; then
							operation_res=false
						fi
						;;
					*)
						if ! ${cmdinst} >"${cmd_output}" 2>&1; then
							operation_res=false
						fi
						;;
				esac

				if ! ${operation_res}; then
					printerr "Failed to install '%s'\n" "${rust_ils_name}"
					>&2 cat "${cmd_output}"
				else
					printf " [done]\n"
				fi
				rm -f "${cmd_output}"

				;;
			list)
				printf "%s\n" "${rust_ils_name}"
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

innershelf_rust()
{
	case "${1}" in
		keyword)
			printf "%s" "rust"
			return 0
			;;
		synopsis)
			printf "%s\n" "Rust (cargo, rustup, rust programs, ..)"
			return 0
			;;
		debug)
			;;
		setup)
			_innershelf_rust_bootstrap
			;;
		dismantle)
			local rustupbase="$(_innershelf_rust_env rustup)"
			local cargobase="$(_innershelf_rust_env cargo)"

			rm -ir "${rustupbase}"
			rm -ir "${cargobase}"
			;;
		packages)
			shift # remove 'packages'
			local subcm=help

			local packages=''
			# local packages="${XDG_DATA_HOME:-${HOME}/.local/share}/rust/packages.${set}.yml"

			local operation='install'
			local option_continue=false

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
					*)
						>&2 printf "Unknown option '%s'" "$1"
						shift
						;;
				esac
			done

			for optsub in $@; do
				case "${optsub}" in
					help|install|list|sets|update)
						subcm="${optsub}"
						;;
					*)
						;;
				esac
			done

			case "${subcm}" in
				sets)
					local available_sets=$(find "${XDG_DATA_HOME:-${HOME}/.local/share}/rust" -name "packages.*.yml" | sed 's,^.*packages\.\(.*\)\.yml,\1,')
					printf "Available sets \n%s\n" "${available_sets}"
					;;
				list)
					_innershelf_rust_packages "${@}"
					;;
				install|update)

					if [ ! -r "${packages}" ]; then
						printerr "Missing file '%s'\n" "${packages}"
						return 1
					fi

					_innershelf_rust_packages "${@}"
					;;
				help|*)
					printf "[%s packages] has\n" "$(innershelf_rust keyword)"
					printf "COMMANDS:\n"
					printf "%-25s# %s\n" "install <set>" "install this set of programs"
					printf "\t%-17s# %s\n" "[-continue]" "continue the operation even if one package fails"
					printf "%-25s# %s\n" "list <set>" "list the programs in this set"
					printf "%-25s# %s\n" "update" "update the programs installed"
					printf "\t%-17s# %s\n" "[-continue]" "continue the operation even if one package fails"
					printf "%-25s# %s\n" "sets" "set(s) that can be installed or listed"
					;;
			esac
			;;
		selfupdate)
			_innershelf_rust_selfup
			;;
		env)
			local rustupbase="$(_innershelf_rust_env rustup)"
			local cargobase="$(_innershelf_rust_env cargo)"
			local cargo_installroot="$(_innershelf_rust_env cargo_installroot)"
			shift

			local new_path >/dev/null
			new_path="${PATH}"

			new_path=$(modify_colon_var "${new_path}" "${cargo_installroot}/bin" pre)
			new_path=$(modify_colon_var "${new_path}" "${cargobase}/bin" post)
			case "${1}" in
				show)
					printf "%s=%s\n%s=%s\n%s=%s\n%s=%s\n"\
						CARGO_HOME  "${CARGO_HOME}"\
						RUSTUP_HOME "${RUSTUP_HOME}"\
						CARGO_INSTALL_ROOT "${CARGO_INSTALL_ROOT}"\
						PATH "${PATH}"

					;;
				set)
					printf "%s=%s\n%s=%s\n%s=%s\n"\
						CARGO_HOME  "${cargobase}"\
						RUSTUP_HOME "${rustupbase}"\
						CARGO_INSTALL_ROOT "${cargo_installroot}"\
						PATH "${new_path}"

					;;
				use)
					export CARGO_HOME="${cargobase}"
					export RUSTUP_HOME="${rustupbase}"
					export CARGO_INSTALL_ROOT="${cargo_installroot}"
					export PATH="${new_path}"
					;;
				clear)
					new_path=$(modify_colon_var "${PATH}" "${cargobase}/bin" remove)
					new_path=$(modify_colon_var "${new_path}" "${cargo_installroot}/bin" remove)
					unset CARGO_HOME RUSTUP_HOME CARGO_INSTALL_ROOT
					export PATH="${new_path}"
					;;
				*)
					printf "[%s env] has\n" "$(innershelf_rust keyword)"
					printf "COMMANDS:\n"
					printf "%-25s# %s\n" "set" "display the desired values (useful for eval())"
					printf "%-25s# %s\n" "show" "shows current value(s)"
					printf "%-25s# %s\n" "use" "export the values as shown in 'set'"
					printf "%-25s# %s\n" "clear" "'unset' the variable(s)"
					;;
			esac
			;;
		help|usage|*)
			printf "[%s] has\n" "$(innershelf_rust keyword)"
			printf "COMMANDS:\n"
			printf "%-25s# %s\n" "setup" "install cargo"
			printf "%-25s# %s\n" "dismantle" "remove cargo, rustup"
			printf "%-25s# %s\n" "env" "environment variables if you need (see env help for more)"
			printf "%-25s# %s\n" "packages" "packages to install/list (see packages help)"
			printf "%-25s# %s\n" "selfupdate" "update Rust toolchain"
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
