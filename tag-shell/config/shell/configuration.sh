#!/bin/bash
# for syntax highlighting keep the line above

if [ -z "${_base_configshell}" ]; then
	. "${XDG_CONFIG_HOME:-${HOME}/.config}"/shell/bases.sh
	. "${_base_configshell}"/envs.sh
	_logging
fi

[ -f "${_base_configshell}/helpers/helpers.sh" ] && . "${_base_configshell}/helpers/helpers.sh"
_inform "loading helpers\n" >>"${SHELL_LOG}" 2>&1
[ -f "${_base_configshell}/helpers/vcs.sh" ] && . "${_base_configshell}/helpers/vcs.sh"
[ -f "${_base_configshell}/helpers/colors.sh" ] && . "${_base_configshell}/helpers/colors.sh"
_inform "loaded helpers\n" >>"${SHELL_LOG}" 2>&1
_shell_XDG >>"${SHELL_LOG}" 2>&1

# Describe the current running system {{{
describe_current_systm() {
	local name sys vers arch model cpu mem

	case $(uname -s) in
		Linux)
			name=$(hostname -s)
			sys=$(lsb_release -sd 2>/dev/null || uname -sr 2>/dev/null)
			arch=$(uname -m 2>/dev/null)
			cpu=$(nproc 2>/dev/null || grep -c '^[Pp]rocessor' /proc/cpuinfo)
			mem=$(expr $(grep MemTotal /proc/meminfo | tr -s ' ' '\t' | cut -f 2) / 1024)
			printf '%s // %s // %s : %d cpu(s) %d MiB RAM' "$name" "$sys" "$arch" "$cpu" "$mem"
			;;
		Darwin)
			name=$(hostname -s)
			sys=$(sw_vers -productName 2>/dev/null | tr -d '\n')
			vers=$(sw_vers -productVersion 2>/dev/null | tr -d '\n')
			model=$(sysctl -n hw.model)
			arch=$(sysctl -n hw.machine)
			cpu=$(sysctl -n hw.ncpu)
			mem=$(expr $(sysctl -n hw.memsize) / 1024 / 1024)
			printf '%s // %s %s // %s (%s) : %d cpu(s) %d MiB RAM' "$name" "$sys" "$vers" "$model" "$arch" "$cpu" "$mem"
			;;
		*BSD)
			name=$(hostname -s)
			sys=$(uname -s)
			vers=$(uname -r)
			arch=$(sysctl -n hw.machine)
			cpu=$(sysctl -n hw.ncpu)
			mem=$(expr $(sysctl -n hw.physmem) / 1024 / 1024)
			printf '%s // %s %s // %s : %d cpu(s) %d MiB RAM' "$name" "$sys" "$vers" "$arch" "$cpu" "$mem"
			;;
		*)
			name=$(hostname -s)
			sys=$(uname -s)
			vers=$(uname -r)
			arch=$(uname -m)
			printf '%s // %s %s // %s' "$name" "$sys" "$vers" "$arch"
			;;
	esac
}
# }}}

# Prompt is an art {{{

# Path, vcs, ... functions {{{

__cwdir() {

	local x_parts=3
	local path_lastpart path_complete hellip

	if [ $# -ge 1 ]; then
		x_parts=$1
	fi

	# initialize p to PWD
	#
	# by default currently it returns the last 3 part of the path
	#
	# an alternative would be to cut a defined length :
	#
	#	     n to max size path
	#
	# p=${p:(-n)} # cut path from end by 'n' length character

	case $(__shell) in
		zsh)
			path_lastpart=$(print -P %$x_parts~ 2>/dev/null)
			path_complete=$(print -P %~ 2>/dev/null)
			hellip=''
			;;
		bash|mksh)
			local path_parts=/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*
			# relace in the home path (if it appears) by '~'
			path_complete=${PWD/#$HOME/'~'}
			path_lastpart=$path_complete

			local extract_path
			extract_path=${path_parts:0:$(($x_parts * 2))}
			# get a reference to the x last part of path_complete
			local last_parts=${path_complete%${extract_path}};
			[ -z "${path_complete:${#last_parts}+1}" ] || path_lastpart=${path_complete:${#last_parts}+1}
			;;
		*)
			path_complete=${PWD/#$HOME/'~'}
			path_lastpart=$path_complete
			;;
	esac

	[ ${#path_complete} != ${#path_lastpart} ] && hellip="‥"

	printf '%s%s' "$hellip" "$path_lastpart"
	return 0
}

__prompt_symbol() {

	local normal='❯' super_user='#' prompt='$' vcs='±' vcs_type=$1

	if __utfenv; then
		normal=$normal
	else
		normal='>'
	fi

	case $(__shell) in
		zsh)
			setopt LOCAL_OPTIONS
			unsetopt EXTENDED_GLOB
			if [ '%' = "$(print -P %# 2>/dev/null)" ]; then
				if [ -z "$vcs_type" ]; then
					prompt=$normal
				else
					prompt=$vcs
				fi
			else
				prompt=$super_user
			fi
			;;
		mksh)
			if (( USER_ID )); then
				if [ -z "$vcs_type" ]; then
					prompt=$normal
				else
					prompt=$vcs
				fi
			else
				prompt=$super_user
			fi
			;;
		bash)
			if (( EUID )); then
				if [ -z "$vcs_type" ]; then
					prompt=$normal
				else
					prompt=$vcs
				fi
			else
				prompt=$super_user
			fi
			;;
	esac

	printf '%s' $prompt
	return 0
}

_set_terminal_window() {

	local tts
	local tte

	if [ $# = 0 ]; then
		return 1 #error
	fi

	case $TERM in
		screen)
			tts=$'\ek'
			tte=$'\e\\'
			;;
		*rxvt*|xterm*)
			tts=$'\e]2;'
			tte=$'\a'
			;;
	esac

	printf '%s' $tts
	printf '%s' "$*"
	printf '%s' $tte

	return 0
}

_set_terminal_tab() {

	local tts
	local tte
	local host
	host=$(ulimit -c 0;hostname 2>&-)

	if [ $# = 0 ]; then
		return 1 #error
	fi

	tts=$'\e]1;'
	tte=$'\a'

	printf '%s' $tts
	if [ ! -z "$SSH_TTY" ]; then
		printf '.: %s :. %s' "$host" "$*"
	else
		printf '%s' "$*"
	fi
	printf '%s' $tte

	return 0
}

# Sets the Terminal.app proxy icon.
_set_terminal_app_proxy_icon() {

	case $(__shell) in
		mksh)
			local host
			host=$(ulimit -c 0;hostname 2>&-)

			printf '%s' $'\e]7;'
			if [ 1 != $# ]; then
				printf '%s' "file://$host$(echo ${PWD} 2>/dev/null| sed -e 's, ,%20,g' 2>/dev/null)"
			fi
			printf '%s' $'\a'
			;;
		zsh)
			if [ 1 = $# ]; then
				printf '\e]7;%s\a' ""
			else
				printf '\e]7;%s\a' "file://$HOST${PWD// /%20}"
			fi

			;;
	esac

	return 0
}

# }}}

# }}}

# shelf_load {{{

shelf_load()
{
	# Add 'shelf' commands/functions {{{

	_inform "Shell loading shelf\n"
	[ -f "${_base_configshell}/helpers/shelf.sh" ] && . "${_base_configshell}/helpers/shelf.sh"
	_inform "Shell loaded elements\n"
	# }}}
}

# }}}

_shell_inners_folder()
{
	local inners_dir

	inners_dir="${_base_configshell}/inner"

	printf "%s" "${inners_dir}"

}

initialize_shell()
{
	[ ! -d "${_base_cacheshell}" ] && install -d "${_base_cacheshell}"

	# Add-ons see .../config/shell/inner directory

	_inform "Loading shelf inners from %s\n" "$(_shell_inners_folder)"
	_shelf_load "$(_shell_inners_folder)"

	# Environment: alias; env{PATH, MANPATH, ...}; different inits; etc.
	_shell_envs

	# Shell vendor specific {{{

	[ -f "${_base_configshell}/shell.$(__shell)" ] && . "${_base_configshell}/shell.$(__shell)"

	# }}}

	if [ ! -f "${_base_configshell}/_no_defaults_prompt" ] ; then
		case $(__shell) in
			zsh)
				typeset -gU path manpath cdpath fpath
				_prompt_zsh_setup
				;;
			mksh)
				_prompt_mksh_setup
				;;
			bash)
				_prompt_bash_setup
				;;
			posix)
				_prompt_posix_setup
				;;
			*)
				;;
		esac
	fi

	_inform "shell checking for 'local host profile': %s\n" "${_base_configshell}/profile"
	[ -f "${_base_configshell}/profile" ] && . "${_base_configshell}/profile"

	_inform "shell initialized\n"
}

# Do initialization first start {{{

case $(__shell) in
	bash|posix)
		case $- in
			*i*)

				printf "%s" "$(terminal_color_code cyan 2>/dev/null)"
				describe_current_systm
				printf "%s" "$(terminal_color_code reset 2>/dev/null)"
				printf '\n'
				shelf_load >>"${SHELL_LOG}" 2>&1
				initialize_shell >>"${SHELL_LOG}" 2>&1
				_shell_XDG >>"${SHELL_LOG}" 2>&1
				;;
			*)
				;;
		esac
		;;
	zsh|mksh)
		if [[ -o interactive ]]; then
			printf "%s" "$(terminal_color_code cyan 2>/dev/null)"
			describe_current_systm
			printf "%s" "$(terminal_color_code reset 2>/dev/null)"
			printf '\n'
			shelf_load >>"${SHELL_LOG}" 2>&1
			initialize_shell >>"${SHELL_LOG}" 2>&1
			_shell_XDG >>"${SHELL_LOG}" 2>&1
		fi
		;;
esac

_inform "Shell configured\n" >>"${SHELL_LOG}" 2>&1

# Hide errors (reset $? to 0)
true

# }}}

# vim: set ft=sh ts=8 sw=8 tw=0 noet fdm=marker:
