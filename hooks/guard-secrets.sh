#!/usr/bin/env bash
# PreToolUse hook for Write, Edit, and MultiEdit. Denies content that carries a
# high-confidence provider key or a literal credential assignment. Placeholders and
# environment lookups pass. Anything the hook cannot read passes.

here=$(cd "$(dirname "$0")" && pwd -P)
. "$here/lib/json.sh"

input=$(cat)
content=$(json_get "$input" tool_input content)
content="$content
$(json_get "$input" tool_input new_string)"
edits=$(json_get "$input" tool_input edits)
if [ -n "$edits" ]; then
  i=0
  while [ "$i" -lt 200 ]; do
    piece=$(json_get "$edits" "$i" new_string)
    [ -n "$piece" ] || break
    content="$content
$piece"
    i=$((i + 1))
  done
fi
[ -n "$(printf '%s' "$content" | tr -d '[:space:]')" ] || exit 0

file=$(json_get "$input" tool_input file_path)

# Provider key formats that have no legitimate placeholder shape.
key_patterns='AKIA[0-9A-Z]{16}
gh[pousr]_[A-Za-z0-9]{36,}
github_pat_[A-Za-z0-9_]{22,}
xox[baprs]-[0-9A-Za-z-]{10,}
sk_live_[0-9a-zA-Z]{24,}
rk_live_[0-9a-zA-Z]{24,}
AIza[0-9A-Za-z_-]{35}
sk-ant-[A-Za-z0-9_-]{40,}
sk-proj-[A-Za-z0-9_-]{40,}
sk-[A-Za-z0-9]{20}T3BlbkFJ[A-Za-z0-9]{20}
npm_[A-Za-z0-9]{36}
glpat-[A-Za-z0-9_-]{20}
-----BEGIN (RSA|EC|DSA|OPENSSH|PGP|ENCRYPTED) PRIVATE KEY-----'

printf '%s\n' "$key_patterns" | while IFS= read -r pattern; do
  [ -n "$pattern" ] || continue
  if printf '%s\n' "$content" | grep -qE -e "$pattern"; then
    printf '%s\n' "$pattern"
    break
  fi
done > "${TMPDIR:-/tmp}/acc-secret-hit.$$"
hit=$(cat "${TMPDIR:-/tmp}/acc-secret-hit.$$")
rm -f "${TMPDIR:-/tmp}/acc-secret-hit.$$"
if [ -n "$hit" ]; then
  hook_deny "Blocked: the content for ${file:-this file} contains what looks like a live credential (pattern $hit). Read it from the environment or a secret store, and keep a placeholder in the file."
  exit 0
fi

# Literal credential assignments: name = "value" with a value that is not a placeholder.
assign_re='(password|passwd|pwd|secret|api[_-]?key|apikey|access[_-]?key|private[_-]?key|auth[_-]?token|access[_-]?token|token|client[_-]?secret)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{8,}["'"'"']'
placeholder_re='^(x+|\*+|\.+|<.*>|\[.*\]|\{\{.*\}\}|\$.*|%.*%|your[-_ ]|changeme|change[-_ ]me|example|placeholder|dummy|sample|test|todo|tbd|redacted|replace|insert|fake|none|null|\.\.\.|secret|password|token)'

printf '%s\n' "$content" | grep -iEo "$assign_re" | while IFS= read -r match; do
  value=$(printf '%s' "$match" | sed 's/^[^:=]*[:=][[:space:]]*["'"'"']//; s/["'"'"']$//')
  lower=$(printf '%s' "$value" | tr 'A-Z' 'a-z')
  if printf '%s' "$lower" | grep -qiE "$placeholder_re"; then continue; fi
  case "$value" in
    *'${'*|*'$('*|*'process.env'*|*'os.environ'*|*'getenv'*|*'{{'*|*'<'*'>'*) continue ;;
  esac
  printf '%s\n' "$match"
  break
done > "${TMPDIR:-/tmp}/acc-secret-hit.$$"
hit=$(cat "${TMPDIR:-/tmp}/acc-secret-hit.$$")
rm -f "${TMPDIR:-/tmp}/acc-secret-hit.$$"
if [ -n "$hit" ]; then
  hook_deny "Blocked: the content for ${file:-this file} assigns a literal credential: '$hit'. Read it from the environment or a secret store, and keep a placeholder in the file."
  exit 0
fi
exit 0
