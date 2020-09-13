#!/bin/bash
# for syntax highlighting keep the line above

_base_configshell="${XDG_CONFIG_HOME:-${HOME}/.config}/shell"
_base_cacheshell="${XDG_CACHE_HOME:-${HOME}/.cache}/shell"
_base_shareshell="${XDG_DATA_HOME:-${HOME}/.local/share}/shell"

if [ -d "${_base_cacheshell}" ]; then
	install -d "${_base_cacheshell}"
fi

# Load add-ons 'add.*.sh' {{{

load_addons()
{
	local addons_dir=${1:-${_base_configshell}}

	for f in "${addons_dir}"/add.*.sh;
	do
		. $f $(dirname "${f}" 2>/dev/null);
	done
}

# }}}

# Load aliases {{{

load_aliases()
{
	local aliases_dir=${1:-${_base_configshell}}

	for f in "${aliases_dir}"/aliases*.sh;
	do
		. $f;
	done
}

# }}}

# Which shell and environment {{{

__shell() {

	if [ ! -z "$ZSH_VERSION" ]; then
		shell_detected=zsh
	elif [ ! -z "$BASH_VERSION" ]; then
		shell_detected=bash
	elif [ ! -z "$KSH_VERSION" ]; then
		if [ "${KSH_VERSION/MIRBSD KSH}" != "$KSH_VERSION" ]; then
			shell_detected=mksh
		fi
	else
		shell_detected=posix
	fi

	printf '%s' $shell_detected
	return 0
}

__utfenv() {
	case "$LANG $CHARSET $LANGUAGE $LC_CTYPE" in
		(*utf*) return 0
			;;
		(*UTF*) return 0
			;;
		(*) return 1
			;;
	esac
}

# }}}

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

# Colors {{{

__escape_code() {

	if [ $# = 0 ] || [ $# -gt 1 ]; then
		return 1
	fi

	color_code=0
	if tput setaf 4 >/dev/null 2>&1; then
		case ${1##bg_} in
			black)
				;;
			red)
				color_code=1
				;;
			green)
				color_code=2
				;;
			yellow)
				color_code=3
				;;
			blue)
				color_code=4
				;;
			magenta)
				color_code=5
				;;
			cyan)
				color_code=6
				;;
			white)
				color_code=7
				;;
			light_black)
				color_code=8
				;;
			light_red)
				color_code=9
				;;
			light_green)
				color_code=10
				;;
			light_yellow)
				color_code=11
				;;
			light_blue)
				color_code=12
				;;
			light_magenta)
				color_code=13
				;;
			light_cyan)
				color_code=14
				;;
			light_white)
				color_code=15
				;;
			e_o_l)
				printf "%s" "$(tput el)"
				;;
			reset|*)
				printf "%s" "$(tput sgr0)"
				;;
		esac

		if [ $color_code -gt 0 ]; then
			[ -z ${1%${1#bg_}} ] && printf "%s" "$(tput setaf "$color_code")" || printf "%s" "$(tput setab "$color_code")"
		fi

	elif tput AF 4 >/dev/null 2>&1; then
		case ${1##bg_} in
			black)
				;;
			red)
				color_code=1
				;;
			green)
				color_code=2
				;;
			yellow)
				color_code=3
				;;
			blue)
				color_code=4
				;;
			magenta)
				color_code=5
				;;
			cyan)
				color_code=6
				;;
			white)
				color_code=7
				;;
			light_black)
				color_code=8
				;;
			light_red)
				color_code=9
				;;
			light_green)
				color_code=10
				;;
			light_yellow)
				color_code=11
				;;
			light_blue)
				color_code=12
				;;
			light_magenta)
				color_code=13
				;;
			light_cyan)
				color_code=14
				;;
			light_white)
				color_code=15
				;;
			e_o_l)
				printf "%s" "$(tput el)"
				;;
			reset|*)
				printf "%s" "$(tput me)"
				;;
		esac

		if [ $color_code -gt 0 ]; then
			[ -z ${1%${1#bg_}} ] && printf "%s" "$(tput AF "$color_code")" || printf "%s" "$(tput AB "$color_code")"
		fi
	fi

	return 0
}

# }}}

# Path, vcs, ... functions {{{

__findir_top_in_hierarchy() {
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

__findir_in_hierarchy() {
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

__vcs_root() {

	[ 1 = $#  ] || return 1
	[ -z "$1" ] && return 1

	local vcs_root=

	case $1 in
		git)
			vcs_root=$(git rev-parse --show-toplevel 2>/dev/null)

			[ -z "$vcs_root" ] && return 1

			if [ ! -z "$vcs_root" ] && [ "--show-toplevel" = "$vcs_root" ]; then
				local rel
				rel=$(git rev-parse --show-cdup 2>/dev/null)
				[ -z "$rel" ] && rel='.'
				vcs_root=$(cd "$rel" 2>/dev/null && pwd -P 2>/dev/null)
			fi
			;;
		hg)
			vcs_root=$(hg root 2>/dev/null)
			;;
		svn)
			vcs_root=$(__findir_top_in_hierarchy '.svn' 2>/dev/null)
			;;
	esac

	[ -z "$vcs_root" ] && return 1

	printf '%s' "$(cd "${vcs_root}" 2>/dev/null && pwd -P 2>/dev/null)"
	return 0
}

__vcs_branch() {

	[ 1 = $#  ] || return 1
	[ -z "$1" ] && return 1

	local vcs_branch=

	case $1 in
		git)
			vcs_branch=$(git symbolic-ref HEAD 2>/dev/null) || return 1
			vcs_branch=${vcs_branch#refs/heads/}
			;;
		hg)
			vcs_branch=$(hg id -b 2>/dev/null)
			;;
		svn)
			vcs_branch=$(LC_ALL=POSIX svn info 2>/dev/null | sed -n s/Revision:\ //p)
			vcs_branch="r${vcs_branch}"
			;;
	esac

	[ -z "$vcs_branch" ] && return 1

	printf '%s' "${vcs_branch}"
	return 0
}

__vcs_state() {

	[ 1 = $#  ] || return 1
	[ -z "$1" ] && return 1

	local vcs_state=

	case $1 in
		git)
			;;
		hg)
			;;
		svn)
			;;
	esac

	[ -z "$vcs_state" ] && return 1

	printf '%s' ${vcs_state}
	return 0
}

__vcs_type() {
	local vcs_system=

	if __findir_in_hierarchy '.git' >/dev/null 2>&1 ; then
		vcs_system='git'
	fi

	if __findir_in_hierarchy '.hg' >/dev/null 2>&1 ; then
		vcs_system='hg'
	fi

	if __findir_top_in_hierarchy '.svn' >/dev/null 2>&1 ; then
		vcs_system='svn'
	fi

	# no result
	[ -z "$vcs_system" ] && return 1

	printf "%s" ${vcs_system}
	return 0
}

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

# shelf_init {{{

shelf_init()
{

	# Add 'shelf' commands/functions {{{

	[ -f "${_base_shareshell}/helpers.sh" ] && . "${_base_shareshell}/helpers.sh"
	[ -f "${_base_shareshell}/yaml.sh" ] && . "${_base_shareshell}/yaml.sh"
	[ -f "${_base_shareshell}/shelf.sh" ] && . "${_base_shareshell}/shelf.sh"

	# }}}

	# Add-ons see .../config/shell directory

	load_addons "${_base_configshell}"

	# Aliases see .../config/shell directory

	load_aliases "${_base_configshell}"
}

# }}}

EDITOR=${EDITOR:-vim}
HISTSIZE=65535                                       # History size in lines
HISTFILE="${_base_cacheshell}/$(__shell)_history"    # History save file
LESSHISTFILE=-                                       # Disable less history

initialize_shell() {

	# Shell vendor specific {{{

	[ -f "${_base_configshell}/shell.$(__shell)" ] && . "${_base_configshell}/shell.$(__shell)"

	# }}}

	export LC_ALL=en_US.UTF-8
	export LANG=en_US.UTF-8
	export LANGUAGE=en_US.UTF-8

	[ -f "${_base_configshell}/profile" ] && . "${_base_configshell}/profile"
	[ -f "${_base_configshell}/specific.sh" ] && . "${_base_configshell}/specific.sh"

	case $(__shell) in
		zsh)
			typeset -gU path manpath cdpath fpath
			_prompt_zsh_setup
			eval "$(fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install zsh-wcomp zsh-wcomp-install)"
			;;
		mksh)
			_prompt_mksh_setup
			eval "$(fasd --init posix-alias posix-hook)"
			;;
		bash)
			_prompt_bash_setup
			eval "$(fasd --init posix-alias bash-hook bash-ccomp bash-ccomp-install)"
			;;
		posix)
			_prompt_posix_setup
			eval "$(fasd --init posix-alias)"
			;;
		*)
			;;
	esac
}

# Do initialization first start {{{

case $(__shell) in
	bash|posix)
		case $- in
			*i*)
				printf "%s" "$(__escape_code cyan)"
				describe_current_systm
				printf "%s" "$(__escape_code reset)"
				printf '\n'
				shelf_init
				initialize_shell
				;;
			*)
				;;
		esac
		;;
	zsh|mksh)
		if [[ -o interactive ]]; then
			printf "%s" "$(__escape_code cyan)"
			describe_current_systm
			printf "%s" "$(__escape_code reset)"
			printf '\n'
			shelf_init
			initialize_shell
		fi
		;;
esac

# Hide errors (reset $? to 0)
true

# }}}

# vim: set ft=sh ts=8 sw=8 tw=0 noet fdm=marker:
