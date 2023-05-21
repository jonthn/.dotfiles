
export LC_ALL=en_GB.UTF-8
export LANG=en_GB.UTF-8
export LANGUAGE=en_GB.UTF-8

install -v -d ${XDG_STATE_HOME}/$(__shell)

export EDITOR=${EDITOR:-vim}
export HISTSIZE=65535                                       # History size in lines
export HISTFILE="${XDG_STATE_HOME}/$(__shell)/history"      # History save file
export LESSHISTFILE=-                                       # Disable less history

case $(uname -s 2>/dev/null) in
	Linux)
		alias ls='ls -F --color=auto'
		;;
	*)
		alias ls='ls -FG'
		;;
esac

alias sl='ls -l'
alias l='ls -la'
alias ll='ls -l'
alias lr='ls -hAlrt'
alias lsd='ls -d *(/)'           # only show directories
alias dir="ls -lSrah"
alias cpv='rsync -aP'            # copy with verbose progress
alias h=" shf_shell_h"

# vim: set ft=sh ts=8 sw=8 tw=0 noet fdm=marker:
