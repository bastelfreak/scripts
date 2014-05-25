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
PS1='[\u@\h \W]\$ '
eval "$(dircolors)"
export LS_OPTIONS='--color=auto -h'
export EDITOR='vim'
export HISTFILESIZE='99999999'
export HISTSIZE='99999999'
export HISTCONTROL='ignoreboth'
