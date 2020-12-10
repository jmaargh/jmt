# Colours: https://coolors.co/212121-272244-3c376d-a9b3ce-f4d35e-dbdbdb

function _jmt_effect {
  case "$1" in
    reset)      echo -e '\033[0m';;
    bold)       echo -e '\033[1m';;
  esac
}

function _jmt_fg {
  case "$1" in
    black)      echo -e '\033[38;2;33;33;33m';;
    red)        echo -e '\033[31m';;
    yellow)     echo -e '\033[38;2;244;211;94m';;
    cyan)       echo -e '\033[36m';;
    white)      echo -e '\033[38;2;219;219;219m';;
    orange)     echo -e '\033[38;5;166m';;
  esac
}

function _jmt_bg {
  case "$1" in
    default)    echo -e '\033[49m';;
    black)      echo -e '\033[40m';;
    green)      echo -e '\033[48;2;128;178;108m';;
    yellow)     echo -e '\033[48;2;244;211;94m';;
    blue)       echo -e '\033[48;2;60;55;109m';;
    pale)       echo -e '\033[48;2;169;179;206m';;
    dark)       echo -e '\033[48;2;39;34;68m';;
    cyan)       echo -e '\033[46m';;
    orange)     echo -e '\033[48;5;166m';;
    red)        echo -e '\033[48;2;165;64;39m';;
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
  echo -e "\001${local_acc}\002"
}

function _jmt_section {
  echo -e "$(_jmt_ctrl effect $3 bg $2 fg $1) ${4} "
}

function _jmt_prompt_prelude {
  # Any scrolling with colourlines is buggy, so we work around it by first writing
  # blank lines for each line we'll draw, then jumping back up that many lines
  if [[ $_JMT_RETVAL -ne 0 ]]; then
    echo -e "$(_jmt_ctrl effect reset)\n\n\[\033[2A\]$(_jmt_ctrl line dark fg red) x$(_jmt_ctrl fg white) $_JMT_RETVAL\n$(_jmt_ctrl line default)"
  else
    echo -e "$(_jmt_ctrl effect reset)\n\[\033[1A\]"
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
  local dirty=''
  local changes=''
  local staged=''
  local new=''

  git diff --no-ext-diff --quiet --exit-code || dirty+="*"
  if [ -n "$(git rev-parse --short HEAD 2>/dev/null)" ]; then
    git diff-index --cached --quiet HEAD -- || dirty+="+"
  else
    dirty+="o"
  fi

  [[ -n $dirty ]] && echo -e " $dirty"
}

function _jmt_current_column {
  local oldstty
  local position
  exec < /dev/tty
  oldstty=$(stty -g)
  stty raw -echo min 0
  echo -en "\033[6n" > /dev/tty
  IFS=';' read -r -d R -a position
  stty $oldstty
  # 0-based indexing
  echo $((${position[1]} - 1))
}

function _jmt_short_line_bang {
  if (( _JMT_START_COLUMN > 0 )); then
    echo "$(_jmt_ctrl bg red fg black)¬\n"
  fi
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
  echo -e "$(_jmt_ctrl line blue)\n$(_jmt_ctrl ${prompt_colour}) \\$"
}

function _jmt_prompt_title {
  if [[ $TERM == xterm* ]]; then
    echo -e "\[\033]0;\u@\h:\w\007\]"
  fi
}

function _jmt_bash_prompt {
  _JMT_RETVAL=$?
  _JMT_START_COLUMN=$(_jmt_current_column)

  PS1="\
$(_jmt_short_line_bang)\
$(_jmt_prompt_prelude)\
$(_jmt_prompt_title)\
$(_jmt_prompt_flags)\
$(_jmt_prompt_host)\
$(_jmt_prompt_dir)\
$(_jmt_prompt_git)\
$(_jmt_prompt_bashprompt)\
$(_jmt_ctrl effect reset) \
"
}

PROMPT_COMMAND=_jmt_bash_prompt
