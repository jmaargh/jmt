# Derived from https://github.com/ohmybash/oh-my-bash/blob/master/themes/agnoster/agnoster.theme.sh
# (which is MIT licenced)

_JMT_CURRENT_BG='NONE'
_JMT_CURRENT_RBG='NONE'
_JMT_SEGMENT_SEPARATOR='▒'
_JMT_GIT_CHANGE_CHARACTER='✶'
_JMT_GIT_STAGED_CHARACTER='+'
_JMT_GIT_FRESH_CHARACTER='○'

function _jmt_text_effect {
  case "$1" in
    reset)      echo 0;;
    bold)       echo 1;;
    underline)  echo 4;;
  esac
}

function _jmt_fg_colour {
  case "$1" in
    black)      echo 30;;
    red)        echo 31;;
    green)      echo 32;;
    yellow)     echo 33;;
    blue)       echo 34;;
    magenta)    echo 35;;
    cyan)       echo 36;;
    white)      echo 37;;
    orange)     echo 38\;5\;166;;
  esac
}

function _jmt_bg_colour {
  case "$1" in
    black)      echo 40;;
    red)        echo 41;;
    green)      echo 42;;
    yellow)     echo 43;;
    blue)       echo 44;;
    magenta)    echo 45;;
    cyan)       echo 46;;
    white)      echo 47;;
    orange)     echo 48\;5\;166;;
  esac;
}

function _jmt_ansi {
  local seq
  declare -a _jmt_acodes=("${!1}")

  seq=""
  for ((i = 0; i < ${#_jmt_acodes[@]}; i++)); do
    if [[ -n $seq ]]; then
      seq="${seq};"
    fi
    seq="${seq}${_jmt_acodes[$i]}"
  done

  echo -ne '\[\033['${seq}'m\]'
}

function _jmt_ansi_single {
  echo -ne '\[\033['$1'm\]'
}

function _jmt_ansi_colourline {
  _jmt_ansi_single $(_jmt_bg_colour blue)
  echo -ne '\[\033[K\]'
}

function _jmt_prompt_segment {
  local bg fg
  declare -a _jmt_codes

  _jmt_codes=("${_jmt_codes[@]}" $(_jmt_text_effect reset))
  if [[ -n $1 ]]; then
    bg=$(_jmt_bg_colour $1)
    _jmt_codes=("${_jmt_codes[@]}" $bg)
  fi
  if [[ -n $2 ]]; then
    fg=$(_jmt_fg_colour $2)
    _jmt_codes=("${_jmt_codes[@]}" $fg)
  fi

  if [[ $_JMT_CURRENT_BG != NONE && $1 != $_JMT_CURRENT_BG ]]; then
    declare -a _jmt_intermediate=($(_jmt_fg_colour $_JMT_CURRENT_BG) $(_jmt_bg_colour $1))
    PR="$PR $(_jmt_ansi _jmt_intermediate[@])$_JMT_SEGMENT_SEPARATOR"
    PR="$PR$(_jmt_ansi _jmt_codes[@]) "
  else
    PR="$PR$(_jmt_ansi _jmt_codes[@]) "
  fi
  _JMT_CURRENT_BG=$1
  [[ -n $3 ]] && PR="$PR$3"
}

function _jmt_prompt_end {
  if [[ -n $_JMT_CURRENT_BG ]]; then
    declare -a _jmt_codes=($(_jmt_text_effect reset) $(_jmt_fg_colour $_JMT_CURRENT_BG))
    PR="$PR $(_jmt_ansi _jmt_codes[@])$_JMT_SEGMENT_SEPARATOR"
  fi
  declare -a _jmt_reset=($(_jmt_text_effect reset))
  PR="$PR $(_jmt_ansi _jmt_reset[@])"
  _JMT_CURRENT_BG=''
}

function _jmt_prompt_status {
  local symbols
  symbols=()
  [[ $_JMT_RETVAL -ne 0 ]] && symbols+="$(_jmt_ansi_single $(_jmt_fg_colour red))✘"
  [[ $UID -eq 0 ]] && symbols+="$(_jmt_ansi_single $(_jmt_fg_colour yellow))⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="$(_jmt_ansi_single $(_jmt_fg_colour cyan))⚙"
  [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_TTY" ]] && symbols+="$(_jmt_ansi_single $(_jmt_fg_colour orange))🔗"

  [[ -n "$symbols" ]] && _jmt_prompt_segment black default "$symbols"
}

function _jmt_prompt_host {
  local user=`whoami`
  _jmt_prompt_segment blue white "$user@\h"
}

function _jmt_prompt_dir {
  _jmt_prompt_segment black white '\w'
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
  local ref dirty
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    _JMT_GIT_PROMPT_DIRTY='±'
    dirty=$(_jmt_git_status_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    if [[ -n $dirty ]]; then
        _jmt_prompt_segment yellow black
    else
        _jmt_prompt_segment green black
    fi
    PR="$PR${ref/refs\/heads\// }$dirty"
  fi
}

function _jmt_prompt_bashprompt {
  PR="$PR $_JMT_SEGMENT_SEPARATOR$(_jmt_ansi_colourline)\n"
  _JMT_CURRENT_BG='NONE'
  _jmt_prompt_segment blue white '$'
}

function _jmt_build_prompt {
  _jmt_prompt_status
  _jmt_prompt_host
  _jmt_prompt_dir
  _jmt_prompt_git
  _jmt_prompt_bashprompt
  _jmt_prompt_end
}

function _jmt_bash_prompt {
  _JMT_RETVAL=$?
  # Clear the background colour
  PR="$(_jmt_ansi_single 49)"
  PRIGHT=''
  _JMT_CURRENT_BG='NONE'
  PR="$(_jmt_ansi_single $(_jmt_text_effect reset))"
  _jmt_build_prompt
  PS1=$PR
}

PROMPT_COMMAND=_jmt_bash_prompt
