#!/usr/bin/env bash
# PostToolUse hook for Write, Edit, and MultiEdit. Records the edited file path so
# verify-gate.sh knows the turn changed something. Records nothing else.

here=$(cd "$(dirname "$0")" && pwd -P)
. "$here/lib/json.sh"
. "$here/lib/state.sh"

input=$(cat)
file=$(json_get "$input" tool_input file_path)
[ -n "$file" ] || exit 0
cwd=$(json_get "$input" cwd)
[ -n "$cwd" ] && cd "$cwd" 2>/dev/null
state_append_unique dirty-files "$file"
exit 0
