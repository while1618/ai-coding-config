#!/usr/bin/env bash
# JSON helpers for hooks. Sourced, not executed.
#
#   json_get <doc> <key ...>       print a value from a JSON document; empty when missing
#   json_backend                   print the backend in use: jq, python3, node, or none
#   json_escape <string>           print the string as a JSON string literal, with quotes
#   hook_deny <reason>             PreToolUse: deny the tool call
#   hook_block_stop <reason>       Stop: block the stop and send the reason back
#   hook_context <event> <text>    add additionalContext for the given event
#
# Backend order is jq, then python3, then node. With none installed, json_get prints
# nothing and returns 0, so every caller fails open.

json_backend() {
  if command -v jq >/dev/null 2>&1; then
    echo jq
  elif command -v python3 >/dev/null 2>&1; then
    echo python3
  elif command -v node >/dev/null 2>&1; then
    echo node
  else
    echo none
  fi
}

# Reads a value by key path. Strings print raw, null prints nothing, compound values
# print as compact JSON. Any backend error prints nothing.
json_get() {
  doc=$1
  shift
  [ -n "$doc" ] || return 0
  case "$(json_backend)" in
    jq)
      filter='.'
      for key in "$@"; do
        case "$key" in
          ''|*[!0-9]*) filter="$filter[\"$(printf '%s' "$key" | sed 's/\\/\\\\/g; s/"/\\"/g')\"]" ;;
          *)           filter="$filter[$key]" ;;
        esac
      done
      printf '%s' "$doc" | jq -r "$filter // empty | if type == \"string\" then . else tojson end" 2>/dev/null
      ;;
    python3)
      printf '%s' "$doc" | python3 -I -c '
import json, sys
keys = sys.argv[1:]
try:
    value = json.load(sys.stdin)
    for key in keys:
        if isinstance(value, list):
            value = value[int(key)]
        elif isinstance(value, dict):
            value = value[key]
        else:
            raise KeyError(key)
except Exception:
    sys.exit(0)
if value is None:
    sys.exit(0)
if isinstance(value, str):
    sys.stdout.write(value)
elif isinstance(value, bool):
    sys.stdout.write("true" if value else "false")
elif isinstance(value, (int, float)):
    sys.stdout.write(json.dumps(value))
else:
    sys.stdout.write(json.dumps(value, separators=(",", ":")))
' "$@" 2>/dev/null
      ;;
    node)
      printf '%s' "$doc" | node -e '
const keys = process.argv.slice(1);
let text = "";
process.stdin.on("data", d => text += d);
process.stdin.on("end", () => {
  let value;
  try {
    value = JSON.parse(text);
    for (const key of keys) {
      if (value === null || typeof value !== "object") process.exit(0);
      value = Array.isArray(value) ? value[Number(key)] : value[key];
      if (value === undefined) process.exit(0);
    }
  } catch (e) { process.exit(0); }
  if (value === null) process.exit(0);
  if (typeof value === "string") process.stdout.write(value);
  else process.stdout.write(JSON.stringify(value));
});
' "$@" 2>/dev/null
      ;;
    *)
      return 0
      ;;
  esac
  return 0
}

# Escapes a string for JSON, with surrounding quotes. Pure bash, so hook responses
# work even when no JSON backend is installed.
json_escape() {
  s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=$(printf '%s' "$s" | awk 'NR > 1 { printf "\\n" } { printf "%s", $0 }')
  s=${s//	/\\t}
  s=${s//$'\r'/\\r}
  printf '"%s"' "$s"
}

hook_deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
    "$(json_escape "$1")"
}

hook_block_stop() {
  printf '{"decision":"block","reason":%s}\n' "$(json_escape "$1")"
}

hook_context() {
  printf '{"hookSpecificOutput":{"hookEventName":%s,"additionalContext":%s}}\n' \
    "$(json_escape "$1")" "$(json_escape "$2")"
}
