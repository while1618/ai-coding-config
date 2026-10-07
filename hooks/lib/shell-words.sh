#!/usr/bin/env bash
# Splits a shell command line into simple commands and words. Sourced, not executed.
#
#   shell_segments <command>   print the command one word per line, with a line holding
#                              only "--" between simple commands
#
# Words are split on whitespace. Quotes and backslashes group text and are stripped.
# ";", "&&", "||", "|", "&", and newline end a simple command. Nothing is expanded, and
# subshells or strings passed to "sh -c" are not descended into, so a hook that reads
# this output inspects only the command positions it can see.

shell_segments() {
  cmd=$1
  len=${#cmd}
  i=0
  word=''
  inword=0
  while [ "$i" -lt "$len" ]; do
    c=${cmd:$i:1}
    case "$c" in
      "'")
        inword=1
        i=$((i + 1))
        while [ "$i" -lt "$len" ] && [ "${cmd:$i:1}" != "'" ]; do
          word="$word${cmd:$i:1}"
          i=$((i + 1))
        done
        ;;
      '"')
        inword=1
        i=$((i + 1))
        while [ "$i" -lt "$len" ] && [ "${cmd:$i:1}" != '"' ]; do
          c=${cmd:$i:1}
          if [ "$c" = '\' ] && [ $((i + 1)) -lt "$len" ]; then
            i=$((i + 1))
            c=${cmd:$i:1}
          fi
          word="$word$c"
          i=$((i + 1))
        done
        ;;
      '\')
        inword=1
        i=$((i + 1))
        [ "$i" -lt "$len" ] && word="$word${cmd:$i:1}"
        ;;
      ' '|'	')
        if [ "$inword" = 1 ]; then printf '%s\n' "$word"; fi
        word=''
        inword=0
        ;;
      ';'|'|'|'&'|$'\n')
        if [ "$inword" = 1 ]; then printf '%s\n' "$word"; fi
        word=''
        inword=0
        printf -- '--\n'
        while [ $((i + 1)) -lt "$len" ]; do
          case "${cmd:$((i + 1)):1}" in
            '|'|'&'|';') i=$((i + 1)) ;;
            *) break ;;
          esac
        done
        ;;
      *)
        inword=1
        word="$word$c"
        ;;
    esac
    i=$((i + 1))
  done
  if [ "$inword" = 1 ]; then printf '%s\n' "$word"; fi
}
