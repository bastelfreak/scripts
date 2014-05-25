#
# ~/.bashrc
#

#
# created by bastelfreak, place this under /etc/skel
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
alias ls='ls $LS_OPTIONS'
alias ll='ls -l'
alias grep='grep --color'

eval "$(dircolors)"

umask 022

export LS_OPTIONS='--color=auto -h'
export EDITOR='vim'
export HISTFILESIZE='99999999'
export HISTSIZE='99999999'
export HISTCONTROL='ignoreboth'
export PS1='\[\033[01;31m\]\u\[\033[01;33m\]@\[\033[01;36m\]\h \[\033[01;33m\]\w \[\033[01;35m\]\$ \[\033[00m\]'

