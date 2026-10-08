#!/usr/bin/env bash
# Checks an ai-coding-config install and reports what the verification gate will run.
#
#   install/doctor.sh --user
#   install/doctor.sh --project <path>
#
# Exit 0 with no problems, 1 when anything needs attention. Drift means a generated file
# no longer matches its source; rerun install/install.sh to regenerate it.

set -u
root=$(cd "$(dirname "$0")/.." && pwd -P)
render="$root/install/lib/render.py"

scope=''; project=''
while [ $# -gt 0 ]; do
  case "$1" in
    --user) scope=user ;;
    --project) scope=project; project=${2:-}; shift ;;
    -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "doctor.sh: unknown option '$1'" >&2; exit 2 ;;
  esac
  shift
done
case "$scope" in
  user) target="$HOME/.claude" ;;
  project)
    [ -n "$project" ] && [ -d "$project" ] || { echo "doctor.sh: --project needs an existing path" >&2; exit 2; }
    project=$(cd "$project" && pwd -P); target="$project/.claude" ;;
  *) echo "doctor.sh: choose --user or --project <path>" >&2; exit 2 ;;
esac

problems=0
problem() { problems=$((problems + 1)); printf 'problem  %s\n' "$1"; }
fine() { printf 'ok       %s\n' "$1"; }

manifest="$target/acc-manifest.json"
[ -f "$manifest" ] || { problem "no manifest at $manifest; run install/install.sh"; exit 1; }
. "$root/hooks/lib/json.sh"
m=$(cat "$manifest")
mode=$(json_get "$m" mode)
# Only a user install links into the config, so only there does its location matter.
if [ "$scope" = user ]; then
  installed_root=$(json_get "$m" root)
  [ "$installed_root" = "$root" ] || problem "manifest points at $installed_root, but this config is at $root"
fi
fine "manifest: mode=$mode"
[ "$(json_backend)" != none ] && fine "JSON backend: $(json_backend)" || problem "no jq, python3, or node: hooks cannot read their input"

i=0
while :; do
  kind=$(json_get "$m" files "$i" kind); path=$(json_get "$m" files "$i" path)
  [ -n "$kind" ] || break
  i=$((i + 1))
  path="$(dirname "$target")/$path"  # manifest paths are relative to the directory that holds .claude
  case "$kind" in
    symlink)
      if [ ! -L "$path" ]; then problem "missing link $path"
      elif [ ! -e "$path" ]; then problem "dangling link $path -> $(readlink "$path")"
      elif [ "$(readlink "$path")" != "$root/${path#*/.claude/}" ] && [ "$(readlink "$path")" != "$root/git-hooks/$(basename "$path")" ]; then
        problem "$path links to $(readlink "$path"), not into $root"
      fi ;;
    copy)
      if [ ! -e "$path" ]; then problem "missing copy $path"
      else
        src="$root/${path#*/.claude/}"
        if [ -e "$src" ] && ! diff -rq "$src" "$path" >/dev/null 2>&1; then
          printf 'drift    %s\n' "$path"
          problem "copy $path differs from $src; rerun install/install.sh to refresh it"
        fi
      fi ;;
    generated|managed-block)
      [ -e "$path" ] || problem "missing generated file $path" ;;
    settings)
      if [ ! -f "$path" ]; then problem "missing $path"
      elif ! grep -q 'ai-coding-config:' "$path"; then problem "$path no longer carries the hook groups"
      fi ;;
    git-config)
      gate=$(cd "$project" && git config --get ai-coding-config.gate 2>/dev/null)
      if [ -z "$gate" ]; then problem "git config ai-coding-config.gate is unset"
      elif [ ! -x "$gate" ]; then problem "gate $gate is not executable"
      fi ;;
  esac
done
fine "$i manifest entries checked"

for script in guard-dangerous-commands validate-commit-msg guard-secrets mark-dirty verify-gate session-start; do
  [ -x "$root/hooks/$script.sh" ] || problem "hook script $script.sh is missing or not executable"
done

# Drift: a dry-run render that would write means the file differs from its source.
drift() {
  python3 "$render" "$@" --dry-run | while IFS= read -r line; do
    case "$line" in
      would\ write\ *) printf 'drift    %s\n' "${line#would write }" ;;
      skipped\ *) printf 'note     %s\n' "$line" ;;
    esac
  done
}
drifted=''
drifted="$drifted$(drift output-style --root "$root" --out "$target/output-styles/plain-technical-english.md")"
hooks_root=$root
[ "$scope" = project ] && hooks_root='"$CLAUDE_PROJECT_DIR"/.claude'
drifted="$drifted$(drift settings-merge --settings "$target/settings.json" --hooks "$root/hooks/hooks.json" --root "$hooks_root")"
if [ "$scope" = project ]; then
  instructions_dir=$project
  drifted="$drifted$(drift managed-block --root "$root" --out "$instructions_dir/AGENTS.md")"
else
  instructions_dir=$target
fi
drifted="$drifted$(drift managed-block --root "$root" --out "$instructions_dir/CLAUDE.md" --import AGENTS.md)"
if [ -n "$drifted" ]; then
  printf '%s\n' "$drifted"
  case "$drifted" in *drift*) problem "generated files drifted; rerun install/install.sh to regenerate" ;; esac
else
  fine "generated files match their sources"
fi

if [ "$scope" = project ]; then
  printf '\nThe gate will run in %s:\n' "$project"
  commands=$("$root/hooks/lib/detect-toolchain.sh" "$project")
  printf '%s\n' "$commands" | awk -F'\t' '$1 != "note" { printf "  %-10s %s%s\n", $1, $2, ($3 == 1 ? "  [+ files]" : "") } $1 == "note" { print "  note: " $2 }'
  if ! printf '%s\n' "$commands" | grep -qv '^note'; then
    problem "no verification commands detected in $project; name them in .agentconfig.json"
  fi
fi

printf '\n'
if [ "$problems" = 0 ]; then echo "No problems."; exit 0; fi
echo "$problems problem(s)."
exit 1
