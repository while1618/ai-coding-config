#!/usr/bin/env bash
# PreToolUse hook for Bash. Denies commands that destroy work:
#   git push --force / -f, git reset --hard, git clean -f, git branch -D,
#   and rm -rf on a path outside the project root.
# Only command positions are inspected, so the same text inside an echo or grep argument
# passes. Anything the hook cannot parse is allowed.

here=$(cd "$(dirname "$0")" && pwd -P)
. "$here/lib/json.sh"
. "$here/lib/shell-words.sh"

input=$(cat)
command=$(json_get "$input" tool_input command)
[ -n "$command" ] || exit 0
cwd=$(json_get "$input" cwd)
[ -n "$cwd" ] || cwd=$PWD
root=$(cd "$cwd" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)
[ -n "$root" ] || root=$cwd

# Collapses "a/./b/../c" without touching the filesystem, so a missing path still resolves.
normalize() {
  out=''
  old_ifs=$IFS
  IFS=/
  for part in $1; do
    case "$part" in
      ''|.) ;;
      ..) out=${out%/*} ;;
      *) out="$out/$part" ;;
    esac
  done
  IFS=$old_ifs
  printf '%s\n' "${out:-/}"
}

outside_root() {
  target=$1
  case "$target" in
    '~'|'~/'*) target="$HOME${target#\~}" ;;
    '$HOME'|'$HOME/'*|'${HOME}'|'${HOME}/'*) target="$HOME${target#*HOME}"; target=${target#\}} ;;
    *'$'*) return 1 ;;
    /*) ;;
    *) target="$cwd/$target" ;;
  esac
  target=$(normalize "$target")
  case "$target" in
    "$root"|"$root"/*) return 1 ;;
  esac
  return 0
}

deny() {
  hook_deny "$1 This destroys work that exists nowhere else. If it is really needed, ask the person to run it."
  exit 0
}

check_git() {
  # $@ are the words after "git". Skip global options to reach the subcommand.
  while [ $# -gt 0 ]; do
    case "$1" in
      -C|-c|--git-dir|--work-tree|--namespace) shift 2; continue ;;
      -*) shift; continue ;;
    esac
    break
  done
  sub=$1
  [ -n "$sub" ] || return 0
  shift
  case "$sub" in
    push)
      for w in "$@"; do
        case "$w" in
          --force|-f|--force-with-lease*|--force-if-includes) deny "Blocked: git push with --force." ;;
          --*) ;;
          -*f*) deny "Blocked: git push with -f." ;;
        esac
      done
      ;;
    reset)
      for w in "$@"; do [ "$w" = --hard ] && deny "Blocked: git reset --hard."; done
      ;;
    clean)
      for w in "$@"; do
        case "$w" in
          --force) deny "Blocked: git clean --force." ;;
          --*) ;;
          -*f*) deny "Blocked: git clean -f." ;;
        esac
      done
      ;;
    branch)
      force=0; delete=0
      for w in "$@"; do
        case "$w" in
          -D|--delete=force) deny "Blocked: git branch -D." ;;
          --force) force=1 ;;
          --delete|-d) delete=1 ;;
          --*) ;;
          -*D*) deny "Blocked: git branch -D." ;;
          -*) case "$w" in *d*) delete=1 ;; esac; case "$w" in *f*) force=1 ;; esac ;;
        esac
      done
      [ "$force$delete" = 11 ] && deny "Blocked: git branch --delete --force."
      ;;
  esac
  return 0
}

check_rm() {
  recursive=0; force=0
  for w in "$@"; do
    case "$w" in
      --recursive) recursive=1 ;;
      --force) force=1 ;;
      --) break ;;
      --*) ;;
      -*) case "$w" in *r*|*R*) recursive=1 ;; esac; case "$w" in *f*) force=1 ;; esac ;;
    esac
  done
  [ "$recursive$force" = 11 ] || return 0
  for w in "$@"; do
    case "$w" in
      -*) continue ;;
    esac
    if outside_root "$w"; then
      deny "Blocked: rm -rf on '$w', which is outside the project root $root."
    fi
  done
  return 0
}

check_segment() {
  # Skip wrappers and env assignments to reach the command word.
  while [ $# -gt 0 ]; do
    case "$1" in
      *=*) shift; continue ;;
      sudo|command|env|nice|time|exec|nohup|builtin) shift; continue ;;
      -*) shift; continue ;;
    esac
    break
  done
  [ $# -gt 0 ] || return 0
  word=$1
  shift
  case "${word##*/}" in
    git) check_git "$@" ;;
    rm) check_rm "$@" ;;
  esac
  return 0
}

segment=''
# Words arrive one per line; "--" alone ends a simple command.
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
