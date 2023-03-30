#!/bin/bash

# Prompt Bash {{{

_prompt_bash_precmd() {
	local e=$?
	local vct
	vct=$(__vcs_type)
	local realpwd
	realpwd=$(cd "$PWD" && pwd -P)

	_prompt_pwd=
	_prompt_vcs=
	_prompt_vcsubdir=
	_prompt_vcsbranch=
	_prompt_vcstate=
	_prompt_color=
	_prompt_error=
	_prompt_prompt=

	if [ ! -z "$vct" ]; then

		if ! _prompt_vcs=$(__vcs_root "$vct"); then
			unset _prompt_vcs
		else
			_prompt_vcsubdir=${realpwd#$_prompt_vcs}
			_prompt_vcsubdir=${_prompt_vcsubdir#?}
			_prompt_vcsbranch=$(__vcs_branch "$vct")
			_prompt_vcstate=$(__vcs_state "$vct")

			[ ! -z "$_prompt_vcs" ] && _prompt_vcs=$(basename "$_prompt_vcs")
			if __utfenv; then
				[ ! -z "$_prompt_vcsubdir" ] && _prompt_vcsubdir='»'$_prompt_vcsubdir
			else
				[ ! -z "$_prompt_vcsubdir" ] && _prompt_vcsubdir=':'$_prompt_vcsubdir
			fi
		fi
	fi

	_prompt_pwd=$(__cwdir)
	_prompt_error=$(printf '%.*s%.*s' $e $e $e ' ')
	_prompt_prompt=$(__prompt_symbol "$vct")

	if [ "$TERM_PROGRAM" = Apple_Terminal ] && command -v update_terminal_cwd >/dev/null; then
		update_terminal_cwd
	fi

	_set_terminal_tab "$_prompt_pwd"

	if [ ! -z "$SSH_TTY" ]; then
		local host
		host=$(ulimit -c 0;hostname -s 2>&-)
		_set_terminal_window "$host"
	else
		_set_terminal_window ""
	fi
}

_prompt_bash_setup() {

	local host_path_separator="τ" # "ϟ" "⚎" "⎆" "⎊"

	local start_code end_code user_color host_color pwd_color vcs_subdir_color
	local vcs_branch_color prompt_error_color prompt_ok_color rst

	start_code="\["
	end_code="\]"
	user_color=$start_code$(terminal_color_code cyan 2>/dev/null)$end_code
	host_color=$start_code$(terminal_color_code magenta 2>/dev/null)$end_code
	pwd_color=$start_code$(terminal_color_code green 2>/dev/null)$end_code
	vcs_subdir_color=$start_code$(terminal_color_code yellow 2>/dev/null)$end_code
	vcs_branch_color=$start_code$(terminal_color_code light_blue 2>/dev/null)$end_code
	prompt_error_color=$start_code$(terminal_color_code light_red 2>/dev/null)$end_code
	prompt_ok_color=$start_code$(terminal_color_code green 2>/dev/null)$end_code
	rst=$start_code$(terminal_color_code reset 2>/dev/null)$end_code

	PROMPT_COMMAND=_prompt_bash_precmd

	PS1="$user_color${SSH_TTY:+\u}$rst${SSH_TTY:+@}"
	PS1+="$host_color\h$rst $host_path_separator "
	PS1+="$pwd_color"'${_prompt_vcs:=${_prompt_pwd}}'"$rst"
	PS1+="$vcs_subdir_color"'${_prompt_vcsubdir}'"$rst "
	PS1+="$vcs_branch_color"'${_prompt_vcsbranch}'"$rst"
	PS1+='${_prompt_vcstate}'"$rst"
	PS1+="\n"
	PS1+="$prompt_ok_color"'${_prompt_error:+'"${prompt_error_color}"'}${_prompt_error}${_prompt_prompt}'"$rst "

	return 0
}

# }}}

if ((BASH_VERSINFO[0] >= 4)); then

_edit_wo_executing() {
	local editor="${EDITOR:-nano}"
	tmpf="$(mktemp)"
	printf '%s\n' "$READLINE_LINE" > "$tmpf"
	"$editor" "$tmpf"
	READLINE_LINE="$(<"$tmpf")"
	READLINE_POINT="${#READLINE_LINE}"
	rm "$tmpf"
}

bind -x '"\C-x\C-e":_edit_wo_executing'

fi
