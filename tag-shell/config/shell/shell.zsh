
# Prompt Zsh {{{

_prompt_elapsed_time() {
	local hours=0
	local mins=0
	local secs=0
	local remainder=0

	if (( 0 == $1 )); then
		return 0
	fi

	if (( $1 >= 3600 )); then
		hours=$(( $1 / 3600 ))
		remainder=$(( $1 % 3600 ))
		mins=$(( remainder / 60 ))
		secs=$(( remainder % 60 ))
		print -P "%{%B%}%{%F{red}%}>>> elapsed time ${hours}h${mins}m${secs}s%{%b%}"
	elif (( $1 >= 60 )); then
		mins=$(( $1 / 60 ))
		secs=$(( $1 % 60 ))
		print -P "%{%B%}%{%F{yellow}%}>>> elapsed time ${mins}m${secs}s%{%b%}"
	else
		print -P "%{%B%}%{%F{green}%}>>> elapsed time ${1}s%{%b%}"
	fi

	return 0
}

_prompt_zsh_preexec() {
	(( $#_elapsed > 1000 )) && set -A _elapsed $_elapsed[-1000,-1]
	typeset -ig _start=SECONDS
}

_prompt_zsh_precmd() {

	local e=$?
	local vct
	vct=$(__vcs_type)

	local timer_result=0
	if (( _start >= 0 )); then
		timer_result=$(( SECONDS-_start ))
		set -A _elapsed "$_elapsed" "$timer_result"
		if (( $timer_result >= 15 )); then
			_prompt_elapsed_time "$timer_result"
		fi
	fi
	_start=-1

	unset _prompt_pwd
	unset _prompt_vcs
	unset _prompt_vcsubdir
	unset _prompt_vcsbranch
	unset _prompt_vcstate
	unset _prompt_color
	unset _prompt_error
	unset _prompt_prompt

	if [ ! -z "$vct" ]; then

		if ! _prompt_vcs=$(__vcs_root "$vct"); then
			unset _prompt_vcs
		else
			_prompt_vcsubdir=${$(pwd -P 2>/dev/null)#$_prompt_vcs}
			_prompt_vcsubdir=${_prompt_vcsubdir#?}
			_prompt_vcsbranch=$(__vcs_branch "$vct")
			_prompt_vcstate=$(__vcs_state "$vct")

			[ ! -z "$_prompt_vcs" ] && _prompt_vcs=$(basename "$_prompt_vcs" 2>/dev/null)
			if __utfenv; then
				[ ! -z "$_prompt_vcsubdir" ] && _prompt_vcsubdir='»'$_prompt_vcsubdir
			else
				[ ! -z "$_prompt_vcsubdir" ] && _prompt_vcsubdir=':'$_prompt_vcsubdir
			fi
		fi
	fi

	_prompt_pwd=$(__cwdir)
	_prompt_error=$(printf '%.*s%.*s' $e $e $e ' ' 2>/dev/null)
	_prompt_prompt=$(__prompt_symbol "$vct")

}

# Unsets the Terminal.app current working directory when a terminal
# multiplexer or remote connection is started since it can no longer be
# updated, and it becomes confusing when the directory displayed in the title
# bar is no longer synchronized with real current working directory.
_terminal_unset_terminal_app_proxy_icon() {
	case "${2[(w)1]:t}" in
		screen|tmux|dvtm|ssh|mosh)
			_set_terminal_app_proxy_icon ' '
			;;
	esac
}

# Sets the tab and window titles with a given command.
_terminal_set_titles_with_command() {
	emulate -L zsh
	setopt EXTENDED_GLOB

	# Set the command name, or in the case of sudo or ssh, the next command.
	local cmd="${${2[(wr)^(*=*|sudo|ssh|-*)]}:t}"
	local truncated_cmd="${cmd/(#m)?(#c15,)/${MATCH[1,12]}...}"
	unset MATCH

	_set_terminal_window "$cmd"
	_set_terminal_tab "$truncated_cmd"
}

# Sets the tab and window titles with a given path.
_terminal_set_titles_with_path() {
	emulate -L zsh
	setopt EXTENDED_GLOB

	local absolute_path="${${1:a}:-$PWD}"
	local abbreviated_path="${absolute_path/#$HOME/~}"
	local truncated_path="${abbreviated_path/(#m)?(#c15,)/...${MATCH[-12,-1]}}"
	unset MATCH

	_set_terminal_window "$abbreviated_path"
	_set_terminal_tab "$truncated_path"
}

_prompt_zsh_setup() {

	prompt_opts=(cr percent subst)

	# Load required functions.
	autoload -Uz add-zsh-hook
	autoload -U colors && colors

	# Add hook for calc elapsed time of this command.
	add-zsh-hook preexec _prompt_zsh_preexec
	# Calc the variables for prompt.
	add-zsh-hook precmd _prompt_zsh_precmd

	# Set up the Apple Terminal.
	if [ "$TERM_PROGRAM" = 'Apple_Terminal' -a -z "$TMUX" ]; then
		# Sets the Terminal.app current working directory before the prompt is
		# displayed.
		add-zsh-hook precmd _set_terminal_app_proxy_icon

		add-zsh-hook preexec _terminal_unset_terminal_app_proxy_icon

		# Do not set the tab and window titles in Terminal.app since it sets the tab
		# title to the currently running process by default and the current working
		# directory is set separately.

	elif ( ! [[ -n "$STY" || -n "$TMUX" ]] ); then

		# Sets the tab and window titles before command execution.
		#add-zsh-hook preexec _terminal_set_titles_with_command

		# Sets the tab and window titles before the prompt is displayed.
		add-zsh-hook precmd _terminal_set_titles_with_path

	fi

	local start_code end_code host_path_separator user_color host_color
	local pwd_color vcs_subdir_color vcs_branch_color prompt_error_color
	local prompt_ok_color rst

	start_code="%{"
	end_code="%}"

	host_path_separator="τ" # "ϟ" "⚎" "⎆" "⎊"
	user_color=$start_code'%F{cyan}'$end_code
	host_color=$start_code'%F{magenta}'$end_code
	pwd_color=$start_code'%F{green}'$end_code
	vcs_subdir_color=$start_code'%F{yellow}'$end_code
	vcs_branch_color=$start_code'%B%F{blue}'$end_code
	prompt_error_color=$start_code'%B%F{red}'$end_code
	prompt_ok_color=$start_code'%B%F{green}'$end_code
	rst=$start_code'%k%f%b'$end_code

	PROMPT=$user_color${SSH_TTY:+%n}$rst${SSH_TTY:+@}
	PROMPT+=$host_color%m$rst" $host_path_separator "
	PROMPT+=$pwd_color'${_prompt_vcs:=${_prompt_pwd}}'$rst
	PROMPT+=$vcs_subdir_color'${_prompt_vcsubdir}'"$rst "
	PROMPT+=$vcs_branch_color'${_prompt_vcsbranch}'$rst
	PROMPT+=$'\n'
	PROMPT+="%(?,$prompt_ok_color,$prompt_error_color)"'${_prompt_error}${_prompt_prompt}'"$rst "

	RPROMPT='%D{%e-%b} %*'

	command_start_time=$SECONDS
	return 0
}

# }}}

# Zsh vendor specific  {{{

bindkey -e # emacs bindings

#HISTSIZE=10000 # The maximum number of events to save in the internal history.
#SAVEHIST=10000 # The maximum number of events to save in the history file.
SAVEHIST=$HISTSIZE  # Saved history size in lines (saved on exiting the shell)

autoload -Uz promptinit && promptinit
setopt promptsubst               # allow 'dynamic content' in prompt
setopt transientrprompt          # remove any right prompt from display when accepting a command line

autoload -z edit-command-line
zle -N edit-command-line
bindkey "^Xe" edit-command-line

# Smart URLs
autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

# Load and initialize the completion system ignoring insecure directories.
autoload -Uz compinit && compinit -i

# autoloading
autoload -U zmv    # who needs mmv or rename?

# noglob so you don't need to quote the arguments of zmv
# mmv *.JPG *.jpg
alias mmv='noglob zmv -W'

#### Options
unsetopt EXTENDED_HISTORY        # DON'T Write the history file in the ':start:elapsed;command' format.
unsetopt SHARE_HISTORY           # DON'T share_history between sessions
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
setopt HIST_VERIFY               # Do not execute immediately upon history expansion.
setopt APPEND_HISTORY

setopt COMPLETE_IN_WORD          # Complete from both ends of a word.
setopt ALWAYS_TO_END             # Move cursor to the end of a completed word.
setopt PATH_DIRS                 # Perform path search even on command names with slashes.
setopt AUTO_MENU                 # Show completion menu on a succesive tab press.
setopt AUTO_LIST                 # Automatically list choices on ambiguous completion.
setopt AUTO_PARAM_SLASH          # If completed parameter is a directory, add a trailing slash.
unsetopt MENU_COMPLETE           # Do not autoselect the first completion entry.
unsetopt FLOW_CONTROL            # DON'T use flow control (^S/^Q)

unsetopt BEEP                    # DON'T emit beep
unsetopt AUTO_CD                 # DON'T change to a directory by entering it as a command
unsetopt EXTENDED_GLOB             # Use extended globbing syntax.
setopt PRINTEIGHTBIT             # Allow eight bit output for completion lists
setopt HASH_LIST_ALL             # hash $PATH before completion

setopt LONGLISTJOBS              # display PID when suspending processes as well
setopt NOTIFY                    # report the status of backgrounds jobs immediately

setopt INTERACTIVECOMMENTS       # allow comments, even in interactive shells
setopt UNSET
unsetopt MAIL_WARNING            # DON'T print a warning message if a mail file has been accessed.

### Completion style

# Use caching to make completion for cammands such as dpkg and apt usable.
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "${ZDOTDIR:-$HOME}/.zcompcache"

# Case-insensitive (all), partial-word, and then substring completion.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
unsetopt CASE_GLOB
#zstyle ':completion:*' matcher-list 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
#setopt CASE_GLOB

# Group matches and describe.
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes

# Fuzzy match mistyped completions.
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# Increase the number of errors based on the length of the typed word.
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'

# Don't complete unavailable commands.
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

# Array completion element sorting.
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# Directories
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
zstyle ':completion:*' squeeze-slashes true

# History
zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes

# Environmental Variables
zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}

# Populate hostname completion.
zstyle -e ':completion:*:hosts' hosts 'reply=(
${=${=${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) 2>/dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
${=${(f)"$(cat /etc/hosts(|)(N) <<(ypcat hosts 2>/dev/null))"}%%\#*}
${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
)'

# Don't complete uninteresting users...
zstyle ':completion:*:*:*:users' ignored-patterns \
	adm amanda apache avahi beaglidx bin cacti canna clamav daemon \
	dbus distcache dovecot fax ftp games gdm gkrellmd gopher \
	hacluster haldaemon halt hsqldb ident junkbust ldap lp mail \
	mailman mailnull mldonkey mysql nagios \
	named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
	operator pcap postfix postgres privoxy pulse pvm quagga radvd \
	rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs '_*'

# ... unless we really want to.
zstyle '*' single-ignored show

# Ignore multiple entries.
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
zstyle ':completion:*:rm:*' file-patterns '*:all-files'

# Kill
zstyle ':completion:*:*:*:*:processes' command 'ps -u $USER -o pid,user,comm -w'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single

# Man
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true


# SSH/SCP/RSYNC
zstyle ':completion:*:(scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

### Aliases nocorrect

alias mv='nocorrect mv'		# no spelling correction on mv
alias mkdir='nocorrect mkdir'
alias man='nocorrect man'

# }}}
