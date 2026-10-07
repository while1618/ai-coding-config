#!/usr/bin/env bash
# Per-repo state for hooks. Sourced, not executed.
#
#   state_dir                      print the state directory, creating it
#   state_read <name>              print the contents of a state file, or nothing
#   state_write <name> <value>     replace a state file
#   state_append_unique <name> <line>   add a line unless it is already present
#   state_clear <name>             remove a state file
#
# Inside a git work tree the state lives in <git-dir>/ai-coding-config/, so each
# worktree keeps its own. Outside git it lives under $TMPDIR, keyed by a hash of cwd.

state_dir() {
  dir=$(git rev-parse --git-dir 2>/dev/null)
  if [ -n "$dir" ]; then
    case "$dir" in
      /*) ;;
      *) dir="$PWD/$dir" ;;
    esac
    dir="$dir/ai-coding-config"
  else
    key=$(printf '%s' "$PWD" | cksum | cut -d' ' -f1)
    dir="${TMPDIR:-/tmp}/ai-coding-config-$key"
  fi
  mkdir -p "$dir" 2>/dev/null
  printf '%s\n' "$dir"
}

state_read() {
  file="$(state_dir)/$1"
  [ -f "$file" ] && cat "$file"
  return 0
}

state_write() {
  printf '%s\n' "$2" > "$(state_dir)/$1"
}

state_append_unique() {
  file="$(state_dir)/$1"
  if [ -f "$file" ] && grep -qxF -- "$2" "$file"; then
    return 0
  fi
  printf '%s\n' "$2" >> "$file"
}

state_clear() {
  rm -f "$(state_dir)/$1"
}
