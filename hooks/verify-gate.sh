#!/usr/bin/env bash
# The verification gate.
#
# Stop mode (no arguments, hook JSON on stdin): when the turn edited files, run the
# detected commands and block the stop on failure. Releases after three failed attempts on
# an unchanged tree, because the model cannot fix what does not change.
#
# Direct mode: verify-gate.sh --files [<path> ...]. Runs the same commands, prints their
# output, and exits non-zero on failure. With no paths, commands run on the whole tree.
#
# AI_CODING_CONFIG_SKIP_VERIFY=1 skips the gate in both modes.

here=$(cd "$(dirname "$0")" && pwd -P)
. "$here/lib/json.sh"
. "$here/lib/state.sh"

[ "${AI_CODING_CONFIG_SKIP_VERIFY:-0}" = 1 ] && exit 0

mode=stop
files=''
if [ "$1" = --files ]; then
  mode=direct
  shift
  for f in "$@"; do files="$files
$f"; done
fi

if [ "$mode" = stop ]; then
  input=$(cat)
  cwd=$(json_get "$input" cwd)
  [ -n "$cwd" ] && cd "$cwd" 2>/dev/null
  files=$(state_read dirty-files)
  [ -n "$files" ] || exit 0
fi

# Keep only files that still exist, as paths relative to here.
existing=''
count=0
old_ifs=$IFS
IFS=$'\n'
for f in $files; do
  [ -n "$f" ] || continue
  rel=$f
  case "$f" in
    "$PWD"/*) rel=${f#"$PWD"/} ;;
  esac
  if [ -f "$rel" ]; then
    existing="$existing$(printf '%q' "$rel") "
    count=$((count + 1))
  fi
done
IFS=$old_ifs

detected=$("$here/lib/detect-toolchain.sh" .)
timeout_seconds=300
gate=''
if [ -f .agentconfig.json ]; then
  config=$(cat .agentconfig.json)
  t=$(json_get "$config" timeoutSeconds)
  case "$t" in ''|*[!0-9]*) ;; *) timeout_seconds=$t ;; esac
  gate=$(json_get "$config" gate | tr -d '[]" ' | tr ',' ' ')
fi

run_with_timeout() {
  if command -v timeout >/dev/null 2>&1; then
    timeout "$timeout_seconds" bash -c "$1"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$timeout_seconds" bash -c "$1"
  else
    bash -c "$1"
  fi
}

failures=''
ran=0
old_ifs=$IFS
IFS=$'\n'
set -- $detected
IFS=$old_ifs
for line in "$@"; do
  category=${line%%	*}
  rest=${line#*	}
  cmd=${rest%	*}
  takes_files=${rest##*	}
  [ "$category" = note ] && continue
  if [ -n "$gate" ]; then
    case " $gate " in *" $category "*) ;; *) continue ;; esac
  fi
  if [ "$takes_files" = 1 ]; then
    if [ "$count" -gt 0 ]; then cmd="$cmd $existing"; else cmd="$cmd ."; fi
  fi
  # Fail open on a tool the machine lacks: the model cannot install it.
  executable=${cmd%% *}
  if ! command -v "$executable" >/dev/null 2>&1; then
    [ "$mode" = direct ] && printf 'verify-gate: skipped "%s", %s is not installed\n' "$cmd" "$executable" >&2
    continue
  fi
  ran=$((ran + 1))
  output=$(run_with_timeout "$cmd" 2>&1)
  rc=$?
  if [ "$mode" = direct ]; then
    printf '%s\n' "$output"
  fi
  if [ "$rc" != 0 ]; then
    tail_out=$(printf '%s\n' "$output" | tail -n 40)
    failures="$failures
[$category] $cmd  (exit $rc)
$tail_out
"
  fi
done

if [ "$mode" = direct ]; then
  if [ -n "$failures" ]; then
    printf '\nverify-gate: failed\n%s\n' "$failures" >&2
    exit 1
  fi
  exit 0
fi

# Stop mode.
if [ -z "$failures" ]; then
  state_clear dirty-files
  state_clear verify-attempts
  exit 0
fi

# Hash the tree as it stands now; three failures on the same hash release the gate.
tree=$( (git status --porcelain 2>/dev/null; git diff 2>/dev/null; for f in $files; do [ -f "$f" ] && cat "$f"; done) | cksum | cut -d' ' -f1)
previous=$(state_read verify-attempts)
prev_hash=${previous%% *}
prev_count=${previous##* }
case "$prev_count" in ''|*[!0-9]*) prev_count=0 ;; esac
if [ "$prev_hash" = "$tree" ]; then
  attempts=$((prev_count + 1))
else
  attempts=1
fi
state_write verify-attempts "$tree $attempts"

if [ "$attempts" -ge 3 ]; then
  state_clear dirty-files
  state_clear verify-attempts
  hook_context Stop "The verification gate failed $attempts times on an unchanged tree and is releasing the turn. Tell the person what still fails:$failures"
  exit 0
fi

hook_block_stop "The verification gate failed (attempt $attempts of 3). Fix these before finishing, or tell the person why you cannot:$failures"
exit 0
