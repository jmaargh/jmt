# Derived from https://github.com/ohmybash/oh-my-bash/blob/master/themes/agnoster/agnoster.theme.sh
# (which is MIT licenced)

_JMT_SEC_BEGIN_CHARACTER=' '
_JMT_SEC_END_CHARACTER=' '
_JMT_END_CHARACTER=' '
_JMT_GIT_CHANGE_CHARACTER='✶'
_JMT_GIT_STAGED_CHARACTER='+'
_JMT_GIT_FRESH_CHARACTER='○'

function _jmt_acc {
  _JMT_ACC="${_JMT_ACC}${1}"
}

function _jmt_ansi {
  _jmt_acc "\033[${1}m"
}

function _jmt_text_effect {
  local code=0
  case "$1" in
    reset)      code='0';;
    bold)       code='1';;
    underline)  code='4';;
  esac
  _jmt_ansi "$code"
}

function _jmt_fg_colour {
  local code=0
  case "$1" in
    black)      code='30';;
    red)        code='31';;
    green)      code='32';;
    yellow)     code='33';;
    blue)       code='34';;
    magenta)    code='35';;
    cyan)       code='36';;
    white)      code='37';;
    orange)     code='38\;5\;166';;
  esac
  _jmt_ansi "$code"
}

function _jmt_bg_colour {
  local code=0
  case "$1" in
    default)    code='49';;
    black)      code='40';;
    red)        code='41';;
    green)      code='42';;
    yellow)     code='43';;
    blue)       code='44';;
    magenta)    code='45';;
    cyan)       code='46';;
    white)      code='47';;
    orange)     code='48\;5\;166';;
  esac
  _jmt_ansi "$code"
}

function _jmt_colourline {
  _jmt_bg_colour $1
  _jmt_acc "\033[K"
}

function _jmt_section {
  local fg=$1
  local bg=$2
  local content=$3

  _jmt_bg_colour "$bg"
  _jmt_fg_colour "$fg"

  _jmt_acc "${_JMT_SEC_BEGIN_CHARACTER}${content}${_JMT_SEC_END_CHARACTER}"
}

function _jmt_prompt_status {
  local acc_backup="${_JMT_ACC}"
  local local_acc=""

  _JMT_ACC=""
  if [[ $_JMT_RETVAL -ne 0 ]]; then
    _jmt_fg_colour red
    _jmt_acc "✘"
  fi
  if [[ $UID -eq 0 ]]; then
    _jmt_fg_colour yellow
    _jmt_acc "⚡"
  fi
  if [[ $(jobs -l | wc -l) -gt 0 ]]; then
    _jmt_fg_colour cyan
    _jmt_acc "⚙"
  fi
  if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
    _jmt_fg_colour orange
    _jmt_acc "🔗"
  fi
  local_acc="${_JMT_ACC}"
  _JMT_ACC="${acc_backup}"

  if [[ -n "${local_acc}" ]]; then
    _jmt_section black default "${local_acc}"
  fi
}

function _jmt_prompt_host {
  local user=`whoami`

  _jmt_section white blue "$user@\h"
}

function _jmt_prompt_dir {
  _jmt_section white black '\w'
}

function _jmt_git_status_dirty {
  changes=''
  staged=''

  git diff --no-ext-diff --quiet --exit-code || changes="$_JMT_GIT_CHANGE_CHARACTER"
  if [ -n "$(git rev-parse --short HEAD 2>/dev/null)" ]; then
    git diff-index --cached --quiet HEAD -- || staged="$_JMT_GIT_STAGED_CHARACTER"
  else
    staged="$_JMT_GIT_FRESH_CHARACTER"
  fi

  dirty="$changes$staged"
  [[ -n $dirty ]] && echo " $dirty"
}

function _jmt_prompt_git {
  local ref dirty background
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    dirty=$(_jmt_git_status_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    if [[ -n $dirty ]]; then
      background="yellow"
    else
      background="green"
    fi
    _jmt_section black $background "${ref/refs\/heads\// }$dirty"
  fi
}

function _jmt_prompt_bashprompt {
  _jmt_colourline blue
  _jmt_fg_colour white
  _jmt_bg_colour blue
  _jmt_acc "\n $"
}

function _jmt_build_prompt {
  _jmt_prompt_status
  _jmt_prompt_host
  _jmt_prompt_dir
  _jmt_prompt_git
  _jmt_prompt_bashprompt
}

function _jmt_bash_prompt {
  _JMT_RETVAL=$?
  _JMT_ACC=""

  _jmt_text_effect reset
  _jmt_bg_colour default
  
  _jmt_build_prompt

  _jmt_text_effect reset
  _jmt_colourline default
  _jmt_acc "${_JMT_END_CHARACTER}"

  PS1=${_JMT_ACC}
}

PROMPT_COMMAND=_jmt_bash_prompt
