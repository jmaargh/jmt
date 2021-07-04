# Colours: https://coolors.co/212121-272244-3c376d-a9b3ce-f4d35e-dbdbdb

function _jmt_effect {
  case "$1" in
    reset)      echo -e '\e[0m';;
    bold)       echo -e '\e[1m';;
  esac
}

function _jmt_fg {
  case "$1" in
    black)      echo -e '\e[38;2;33;33;33m';;
    red)        echo -e '\e[31m';;
    yellow)     echo -e '\e[38;2;244;211;94m';;
    cyan)       echo -e '\e[36m';;
    white)      echo -e '\e[38;2;219;219;219m';;
    orange)     echo -e '\e[38;5;166m';;
  esac
}

function _jmt_bg {
  case "$1" in
    default)    echo -e '\e[49m';;
    black)      echo -e '\e[40m';;
    green)      echo -e '\e[48;2;128;178;108m';;
    yellow)     echo -e '\e[48;2;244;211;94m';;
    blue)       echo -e '\e[48;2;60;55;109m';;
    pale)       echo -e '\e[48;2;169;179;206m';;
    dark)       echo -e '\e[48;2;39;34;68m';;
    cyan)       echo -e '\e[46m';;
    orange)     echo -e '\e[48;5;166m';;
    red)        echo -e '\e[48;2;165;64;39m';;
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
    esac
    shift
  done
  echo -e "\[${local_acc}\]"
}

function _jmt_section {
  local content=" $4 "
  _JMT_PS1_NC+="$content"
  # effect comes first because if it's reset it would override the colours
  _JMT_PS1+="$(_jmt_ctrl effect $3 bg $2 fg $1)$content"
}

function _jmt_prompt_prelude {
  if [[ $_JMT_RETVAL -ne 0 ]]; then
    # It's necessary to pad ignoring colour control characters, so we need to
    # pre-calculate how many of those we have
    _jmt_section red dark bold "x"
    local padding=$(($COLUMNS - 3))  # 3 chars for the x and two spaces
    _JMT_PS1+="$(_jmt_ctrl effect reset fg white bg dark)$(printf "%-${padding}s\n" "$_JMT_RETVAL" )"
  fi
}

function _jmt_prompt_flags {
  local acc=""
  local acc_nc=""

  if [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]]; then
    acc+="$(_jmt_ctrl fg orange)@"
    acc_nc+="@"
  fi
  if [[ $UID -eq 0 ]]; then
    acc+="$(_jmt_ctrl fg yellow)#"
    acc_nc+="#"
  fi
  if [[ -n "$(jobs -l)" ]]; then
    acc+="$(_jmt_ctrl fg cyan)▣"
    acc_nc+="▣"
  fi

  if [[ -n "${acc_nc}" ]]; then
    _JMT_PS1+="$(_jmt_ctrl effect bold bg dark) $acc "
    _JMT_PS1_NC+=" $acc_nc "
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
  # https://unix.stackexchange.com/a/183121/290035
  local row
  local col
  IFS=';' read -sdR -p $'\E[6n' row col
  echo $(($col - 1))  # 0-based indexing
}


function _jmt_short_line_bang {
  if (( _JMT_START_COLUMN > 0 )); then
    _JMT_PS1+="$(_jmt_ctrl bg red fg black)¬$(_jmt_ctrl effect reset)\n"
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

function _jmt_prompt_time {
  let "available_columns = $COLUMNS - $1"
  if $JMT_FORCETIME || (( $available_columns >= 10 )) || (( $available_columns < 0 )); then
    local content=" \t "
    # Reset must come first
    local content_format="$(_jmt_ctrl effect reset bg blue fg white)"
    let "padding = $available_columns - 6 + ${#content_format}"  # 6 because $content expands from " \t " to " HH:MM:SS "
    _JMT_PS1+="$(_jmt_ctrl bg dark)$(printf "%${padding}s" "$content_format$content")"
  else
    _JMT_PS1+="$(_jmt_ctrl bg dark)$(printf "%*s" $available_columns "")"
  fi
}

function _jmt_prompt_bashprompt {
  local foreground="white"
  if [[ $UID -eq 0 ]]; then
    foreground="yellow"
  fi
  _JMT_PS1+="$(_jmt_ctrl effect reset)\n$(_jmt_ctrl effect reset fg $foreground bg blue) \\$"
}

function _jmt_prompt_title {
  if [[ $TERM == xterm* ]]; then
    _JMT_PS1+="\[\033]0;\u@\h:\w\007\]"
  fi
}

function _jmt_prompt_reset {
  # the reset code should reset fg, bg, and effects
  _JMT_PS1+="$(_jmt_ctrl effect reset)"
}

function _jmt_bash_prompt {
  # Only show three levels of dirs by default
  : ${PROMPT_DIRTRIM:=3}
  : ${JMT_FORCETIME:=false}

  _JMT_RETVAL=$?
  _JMT_START_COLUMN=$(_jmt_current_column)

  _JMT_PS1=""
  _JMT_PS1_NC=""  # No control characters

  _jmt_short_line_bang
  _jmt_prompt_prelude
  _jmt_prompt_title

  _JMT_PS1_NC=""
  _jmt_prompt_flags
  _jmt_prompt_host
  _jmt_prompt_dir
  _jmt_prompt_git

  local mainline_rendered="${_JMT_PS1_NC@P}"

  _jmt_prompt_time ${#mainline_rendered}
  _jmt_prompt_bashprompt
  _jmt_prompt_reset

  # Add the final space here
  PS1="$_JMT_PS1 "
}

PROMPT_COMMAND=_jmt_bash_prompt
