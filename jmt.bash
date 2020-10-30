# Colours: https://coolors.co/212121-272244-3c376d-a9b3ce-f4d35e-dbdbdb

function _jmt_effect {
  case "$1" in
    reset)      echo '\033[0m';;
    bold)       echo '\033[1m';;
  esac
}

function _jmt_fg {
  case "$1" in
    black)      echo '\033[38;2;33;33;33m';;
    red)        echo '\033[31m';;
    yellow)     echo '\033[38;2;244;211;94m';;
    cyan)       echo '\033[36m';;
    white)      echo '\033[38;2;219;219;219m';;
    orange)     echo '\033[38;5;166m';;
  esac
}

function _jmt_bg {
  case "$1" in
    default)    echo '\033[49m';;
    black)      echo '\033[40m';;
    green)      echo '\033[48;2;128;178;108m';;
    yellow)     echo '\033[48;2;244;211;94m';;
    blue)       echo '\033[48;2;60;55;109m';;
    pale)       echo '\033[48;2;169;179;206m';;
    dark)       echo '\033[48;2;39;34;68m';;
    cyan)       echo '\033[46m';;
    orange)     echo '\033[48;5;166m';;
  esac
}

function _jmt_ctrl {
  local local_acc=""
  while (( "$#" )); do
    case "$1" in
      fg)
        local_acc+=$(_jmt_fg $2)
        shift
        ;;
      bg)
        local_acc+=$(_jmt_bg $2)
        shift
        ;;
      effect)
        local_acc+=$(_jmt_effect $2)
        shift
        ;;
      line)
        local_acc+="$(_jmt_bg $2)\033[K"
        shift
        ;;
    esac
    shift
  done
  echo "\[${local_acc}\]"
}

function _jmt_section {
  echo "$(_jmt_ctrl effect $3 bg $2 fg $1) ${4} "
}

function _jmt_prompt_prev {
  if [[ $_JMT_RETVAL -ne 0 ]]; then
    echo "$(_jmt_ctrl line dark fg red) x$(_jmt_ctrl fg white) $_JMT_RETVAL\n$(_jmt_ctrl line default)"
  fi
}

function _jmt_prompt_flags {
  local local_acc=""

  if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
    local_acc+="$(_jmt_ctrl fg orange)@"
  fi
  if [[ $UID -eq 0 ]]; then
    local_acc+="$(_jmt_ctrl fg yellow)#"
  fi
  if [[ $(jobs -l | wc -l) -gt 0 ]]; then
    local_acc+="$(_jmt_ctrl fg cyan)▣"
  fi

  if [[ -n "${local_acc}" ]]; then
    _jmt_section black dark bold "${local_acc}"
  fi
}

function _jmt_prompt_host {
  _jmt_section white blue reset "\u@\h"
}

function _jmt_prompt_dir {
  _jmt_section black pale reset '\w'
}

function _jmt_git_status_dirty {
  changes=''
  staged=''
  new=''

  git diff --no-ext-diff --quiet --exit-code || changes="*"
  if [ -n "$(git rev-parse --short HEAD 2>/dev/null)" ]; then
    git diff-index --cached --quiet HEAD -- || staged="+"
  else
    new="o"
  fi

  echo "$changes$staged$new"
}

function _jmt_prompt_git {
  local ref dirty background
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    dirty=$(_jmt_git_status_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="┑ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    if [[ -n $dirty ]]; then
      background="yellow"
    else
      background="green"
    fi
    _jmt_section black $background reset "${ref/refs\/heads\//┝ }$dirty"
  fi
}

function _jmt_prompt_bashprompt {
  local prompt_colour="fg white"
  if [[ $UID -eq 0 ]]; then
    prompt_colour="fg yellow"
  fi
  echo "$(_jmt_ctrl line blue bg blue ${prompt_colour})\n \\$"
}

function _jmt_bash_prompt {
  _JMT_RETVAL=$?

  PS1="\
$(_jmt_ctrl effect reset bg default)\
$(_jmt_prompt_prev)\
$(_jmt_prompt_flags)\
$(_jmt_prompt_host)\
$(_jmt_prompt_dir)\
$(_jmt_prompt_git)\
$(_jmt_prompt_bashprompt)\
$(_jmt_ctrl effect reset line default) \
"
}

PROMPT_COMMAND=_jmt_bash_prompt
