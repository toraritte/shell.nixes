#!/bin/sh

# If  not running  interactively,  don't do  anything;
# this is important for remote shells:
# http://unix.stackexchange.com/questions/257571/why-does-bashrc-check-whether-the-current-shell-is-interactive

echo "EXECUTING SHELL HOOK"

case $- in
  *i*) ;;
  *) return;;
esac

set -o vi

# ==============================================================
# prompt =======================================================
# ==============================================================

CWD=$(pwd)
cd ~
if [ ! -f ~/git-prompt.sh ]; then
  curl -O https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
fi
source ~/git-prompt.sh
cd $CWD

# + for staged, * if unstaged.
export GIT_PS1_SHOWDIRTYSTATE=1¬

# $ if something is stashed.
export GIT_PS1_SHOWSTASHSTATE=1¬

# % if there are untracked files.
export GIT_PS1_SHOWUNTRACKEDFILES=1¬

# <,>,<> behind, ahead, or diverged from upstream.
export GIT_PS1_SHOWUPSTREAM=1

# "She's saying ... a bunch of stuff. Look, have you tried drugs?"
export PS1='NIX-SHELL \[\e[33m\]$(__git_ps1 "%s") \[\e[m\]\[\e[32m\]\u@\h \[\e[m\] \[\e[01;30m\][\w]\[\033[0m\]\nNIX-SHELL \j \[\e[01;30m\][\t]\[\033[0m\] '

# ==============================================================
# history ======================================================
# ==============================================================
export HISTCONTROL=ignoredups # no duplicate lines in history
export HISTSIZE=200000
export HISTFILESIZE=200000
export HISTTIMEFORMAT='%Y/%m/%d-%H:%M '

# ==============================================================
# miscellaneous ================================================
# ==============================================================
# Make sure that tmux uses the right variable in order to
# display vim colors correctly.

export TERM="screen-256color"
export EDITOR=$(which vim)
export MANWIDTH=72
export ERL_AFLAGS="-kernel shell_history enabled"

# Android Studio would only open up with blank windows
# https://unix.stackexchange.com/questions/368817/blank-android-studio-window-in-dwm/428908#428908
export _JAVA_AWT_WM_NONREPARENTING=1

# ==============================================================
# fzf ==========================================================
# ==============================================================
export FZF_DEFAULT_COMMAND='find .'
export FZF_DIR_ONLY="${FZF_DEFAULT_COMMAND} -type d"
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_ALT_C_COMMAND=$FZF_DIR_ONLY

export FZF_DEFAULT_OPTS="--height 70% +i"
export FZF_CTRL_R_OPTS=$FZF_DEFAULT_OPTS

export FZF_TMUX=$(which fzf-tmux)
export FZF_TMUX_OPTS=$FZF_DEFAULT_OPTS
export FZF_TMUX_HEIGHT="70%"

export FZF_ALT_C_OPTS=$FZF_DEFAULT_OPTS" --multi"
export FZF_CTRL_T_OPTS=$FZF_ALT_C_OPTS" --preview='head -$LINES {}'"
export FZF_COMPLETION_OPTS=$FZF_CTRL_T_OPTS

# ==============================================================
# unified bash history =========================================
# ==============================================================
# HIT ENTER FIRST IF LAST COMMAND IS NOT SEEN IN ANOTHER WINDOW
# http://superuser.com/questions/37576/can-history-files-be-unified-in-bash
# (`histappend` in `shellOptions` above is also part of this)

export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r" # help history
shopt -s histappend # man shopt

# ==============================================================
# shell options (cont.) ========================================
# ==============================================================

# Glob hidden files too with *

shopt -s dotglob

# Check  the window  size after  each command  and, if
# necessary, update the values of LINES and COLUMNS.

shopt -s checkwinsize

# If  set,  the  pattern   "**"  used  in  a  pathname
# expansion context  will match all files  and zero or
# more directories and subdirectories.

shopt -s globstar

# Set variable identifying the chroot you work in (used in the prompt below)

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# Enable bash support for FZF

source "$(fzf-share)/key-bindings.bash"
source "$(fzf-share)/completion.bash"

# ==============================================================
# aliases ======================================================
# ==============================================================

alias ll='ls -alF --group-directories-first --color'
alias g='egrep --colour=always -i'
alias ag='ag --hidden'
alias b='bc -lq'
alias dt="date +%Y/%m/%d-%H:%M"
alias r='fc -s' # repeat the last command
alias tmux='tmux -2' # make tmux support 256 color

alias gl='git v --color=always | less -r'
alias glv='git v --color=always --all | less -r'
alias glh="gl | head"

alias ga='git van --color=always | less -r'
alias gav='git van --color=always --all | less -r'
alias gah="ga | head"

alias gd='git vn --color=always | less -r'
alias gdv='git vn --color=always --all | less -r'
alias gdh="gd | head"

# http://www.gnu.org/software/bash/manual/bashref.html#Special-Parameters

tl() {
  tree -C $@ | less -R
}
