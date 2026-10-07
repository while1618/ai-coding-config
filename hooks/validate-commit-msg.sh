#!/usr/bin/env bash
# PreToolUse hook for Bash. Checks the subject line of "git commit -m":
#   type(scope): subject   with the subject 72 characters or fewer, starting
#   in lower case, with no trailing period.
# Merge, revert, fixup, and squash messages pass, and so does a commit without -m.

here=$(cd "$(dirname "$0")" && pwd -P)
. "$here/lib/json.sh"
. "$here/lib/shell-words.sh"

input=$(cat)
command=$(json_get "$input" tool_input command)
case "$command" in
  *git*commit*) ;;
  *) exit 0 ;;
esac

types='feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert'
subject_re="^($types)(\([a-z0-9][a-z0-9-]*\))?!?: [a-z0-9]"

check_message() {
  msg=$1
  subject=${msg%%$'\n'*}
  case "$subject" in
    Merge\ *|Revert\ *|fixup!*|squash!*|amend!*) return 0 ;;
  esac
  if ! [[ $subject =~ $subject_re ]]; then
    hook_deny "Commit subject does not match 'type(scope): subject': '$subject'. The type is one of $types, the scope is kebab-case, and the subject starts in lower case."
    exit 0
  fi
  case "$subject" in
    *.) hook_deny "Commit subject ends with a period: '$subject'. Remove it."; exit 0 ;;
  esac
  if [ "${#subject}" -gt 72 ]; then
    hook_deny "Commit subject is ${#subject} characters; the limit is 72: '$subject'."
    exit 0
  fi
  return 0
}

check_segment() {
  # Find "git ... commit" and its first -m value.
  while [ $# -gt 0 ] && [ "${1##*/}" != git ]; do shift; done
  [ $# -gt 0 ] || return 0
  shift
  while [ $# -gt 0 ]; do
    case "$1" in
      -C|-c|--git-dir|--work-tree) shift 2; continue ;;
      -*) shift; continue ;;
    esac
    break
  done
  [ "$1" = commit ] || return 0
  shift
  while [ $# -gt 0 ]; do
    case "$1" in
      --fixup=*|--squash=*|--fixup|--squash) return 0 ;;
      -m|--message) [ $# -gt 1 ] && check_message "$2"; return 0 ;;
      --message=*) check_message "${1#--message=}"; return 0 ;;
      -m?*) check_message "${1#-m}"; return 0 ;;
    esac
    shift
  done
  return 0
}

words=$(shell_segments "$command")
old_ifs=$IFS
IFS=$'\n'
set -- $words
IFS=$old_ifs
args=''
n=0
for w in "$@"; do
  if [ "$w" = -- ]; then
    eval "check_segment $args"
    args=''
    n=0
  else
    n=$((n + 1))
    eval "seg_$n=\$w"
    args="$args \"\$seg_$n\""
  fi
done
eval "check_segment $args"
exit 0
