#!/usr/bin/env bash
# SessionStart hook. Tells Claude which verification commands the gate will run.

here=$(cd "$(dirname "$0")" && pwd -P)
. "$here/lib/json.sh"

input=$(cat)
cwd=$(json_get "$input" cwd)
[ -n "$cwd" ] || cwd=$PWD

lines=$("$here/lib/detect-toolchain.sh" "$cwd")
commands=$(printf '%s\n' "$lines" | awk -F'\t' '$1 != "note" { print "- " $1 ": " $2 }')
notes=$(printf '%s\n' "$lines" | awk -F'\t' '$1 == "note" && $2 !~ /^no verification commands/ { print "- " $2 }')

if [ -n "$commands" ]; then
  text="Verification gate: when a turn edits files, the Stop hook runs these and blocks on failure.
$commands"
else
  text="Verification gate: no commands detected, so the Stop hook has nothing to run. Name them in .agentconfig.json (keys test, lint, typecheck, format)."
fi
[ -n "$notes" ] && text="$text
Notes:
$notes"
hook_context SessionStart "$text"
exit 0
