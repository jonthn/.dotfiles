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
alias h=" h"

alias ssa='ssh_anonymous'
alias sca='scp_anonymous'

# vim: set ft=sh ts=8 sw=8 tw=0 noet :
