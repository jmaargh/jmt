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

function _jmt_effect {
  local code=0
  case "$1" in
    reset)      code='\033[0m';;
    bold)       code='\033[1m';;
    underline)  code='\033[4m';;
  esac
  _jmt_acc "$code"
}

function _jmt_fg {
  local code=0
  case "$1" in
    black)      code='\033[30m';;
    red)        code='\033[31m';;
    green)      code='\033[32m';;
    yellow)     code='\033[33m';;
    blue)       code='\033[34m';;
    magenta)    code='\033[35m';;
    cyan)       code='\033[36m';;
    white)      code='\033[37m';;
    orange)     code='\033[38\;5\;166m';;
  esac
  _jmt_acc "$code"
}

function _jmt_bg {
  local code=0
  case "$1" in
    default)    code='\033[49m';;
    black)      code='\033[40m';;
    red)        code='\033[41m';;
    green)      code='\033[42m';;
    yellow)     code='\033[43m';;
    blue)       code='\033[44m';;
    magenta)    code='\033[45m';;
    cyan)       code='\033[46m';;
    white)      code='\033[47m';;
    orange)     code='\033[48\;5\;166m';;
  esac
  _jmt_acc "$code"
}

function _jmt_ctrl {
  _jmt_acc "\["
  while (( "$#" )); do
    case "$1" in
      fg)
        _jmt_fg $2
        shift
        ;;
      bg)
        _jmt_bg $2
        shift
        ;;
      effect)
        _jmt_effect $2
        shift
        ;;
      line)
        _jmt_bg $2
        _jmt_acc "\033[K"
        shift
        ;;
    esac
    shift
  done
  _jmt_acc "\]"
}

function _jmt_section {
  _jmt_ctrl bg $2 fg $1
  _jmt_acc "${_JMT_SEC_BEGIN_CHARACTER}${3}${_JMT_SEC_END_CHARACTER}"
}

function _jmt_prompt_status {
  local acc_backup="${_JMT_ACC}"
  local local_acc=""

  _JMT_ACC=""
  if [[ $_JMT_RETVAL -ne 0 ]]; then
    _jmt_ctrl fg red
    _jmt_acc "✘"
  fi
  if [[ $UID -eq 0 ]]; then
    _jmt_ctrl fg yellow
    _jmt_acc "⚡"
  fi
  if [[ $(jobs -l | wc -l) -gt 0 ]]; then
    jmt_ctrl fg cyan
    _jmt_acc "⚙"
  fi
  if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
    _jmt_ctrl fg orange
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
  _jmt_ctrl line blue fg white bg blue
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

  _jmt_ctrl effect reset bg default
  
  _jmt_build_prompt

  _jmt_ctrl effect reset line default
  _jmt_acc "${_JMT_END_CHARACTER}"

  PS1=${_JMT_ACC}
}

PROMPT_COMMAND=_jmt_bash_prompt
