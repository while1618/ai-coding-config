#!/usr/bin/env bash
# Installs ai-coding-config into the user scope or a project.
#
#   install/install.sh --user [--copy] [--dry-run]
#   install/install.sh --project <path> [--copy] [--dry-run] [--no-git-hooks]
#
# Skills, rules, and agents are symlinked (or copied with --copy). Project rules are always
# copied, because Claude Code does not load a project rule that links outside the project. No existing file is ever
# overwritten: a file that is already there is reported and left alone. settings.json is
# backed up to settings.json.acc-backup before the hook groups are merged in. A manifest
# of everything installed is written next to the settings file.

set -u

root=$(cd "$(dirname "$0")/.." && pwd -P)
render="$root/install/lib/render.py"

scope=''
project=''
mode=symlink
dry_run=0
git_hooks=1

usage() { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --user) scope=user ;;
    --project) scope=project; project=${2:-}; shift ;;
    --copy) mode=copy ;;
    --dry-run) dry_run=1 ;;
    --no-git-hooks) git_hooks=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "install.sh: unknown option '$1'" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

case "$scope" in
  user) target="$HOME/.claude" ;;
  project)
    [ -n "$project" ] || { echo "install.sh: --project needs a path" >&2; exit 2; }
    mkdir -p "$project" 2>/dev/null
    project=$(cd "$project" && pwd -P) || { echo "install.sh: cannot open $project" >&2; exit 2; }
    target="$project/.claude"
    ;;
  *) echo "install.sh: choose --user or --project <path>" >&2; usage >&2; exit 2 ;;
esac
command -v python3 >/dev/null 2>&1 || { echo "install.sh: python3 is required" >&2; exit 2; }

manifest_entries=''
record() { manifest_entries="$manifest_entries$1	$2
"; }
say() { printf '%s\n' "$*"; }
dry() { [ "$dry_run" = 1 ]; }

# Copies an earlier install recorded are ours, so a rerun may refresh them.
owned=''
if [ -f "$target/acc-manifest.json" ]; then
  owned=$(python3 -c 'import json, sys
for f in json.load(open(sys.argv[1])).get("files", []):
    if f.get("kind") == "copy": print(f["path"])' "$target/acc-manifest.json" 2>/dev/null)
fi
is_owned() { printf '%s\n' "$owned" | grep -qxF -- "$1"; }

# place <src> <dst> [symlink|copy]: link or copy, never over a file this config does not own.
place() {
  src=$1; dst=$2; how=${3:-$mode}
  if [ "$how" = symlink ] && [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    say "already   $dst"; record symlink "$dst"; return 0
  fi
  if [ "$how" = copy ] && [ -e "$dst" ] && [ ! -L "$dst" ] && diff -rq "$src" "$dst" >/dev/null 2>&1; then
    say "already   $dst"; record copy "$dst"; return 0
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$how" = copy ] && is_owned "$dst"; then
      if dry; then say "would update $dst"
      else rm -rf "$dst"; cp -R "$src" "$dst"; say "updated   $dst"; fi
      record copy "$dst"; return 0
    fi
    say "skipped   $dst (exists; not overwritten)"; return 0
  fi
  if dry; then say "would $how $dst -> $src"; record "$how" "$dst"; return 0; fi
  mkdir -p "$(dirname "$dst")"
  if [ "$how" = copy ]; then cp -R "$src" "$dst"; else ln -s "$src" "$dst"; fi
  say "$how   $dst"
  record "$how" "$dst"
}

# Runs a render.py subcommand, echoes its report, and records files it wrote.
render_to() {
  kind=$1; shift
  if dry; then set -- "$@" --dry-run; fi
  python3 "$render" "$@" | while IFS= read -r line; do
    say "$line"
    case "$line" in
      would\ write\ *) printf '%s\t%s\n' "$kind" "${line#would write }" >> "$entries_file" ;;
      wrote\ *|updated\ *|unchanged\ *) printf '%s\t%s\n' "$kind" "${line#* }" >> "$entries_file" ;;
    esac
  done
}
entries_file=$(mktemp "${TMPDIR:-/tmp}/acc-install.XXXXXX")

say "ai-coding-config at $root"
say "scope: $scope, target: $target, mode: $mode$(dry && printf ' (dry run)')"
say ''

# --- Claude Code -------------------------------------------------------------
for skill in "$root"/skills/*/; do
  name=$(basename "$skill")
  place "${skill%/}" "$target/skills/$name"
done
# Claude Code does not load a project rule that symlinks outside the project, so project
# rules are always copies. User-scope rules may stay links.
rule_mode=$mode
[ "$scope" = project ] && rule_mode=copy
for rule in "$root"/rules/*.md; do
  place "$rule" "$target/rules/$(basename "$rule")" "$rule_mode"
done
for agent in "$root"/agents/*.md; do
  place "$agent" "$target/agents/$(basename "$agent")"
done

render_to generated output-style --root "$root" --out "$target/output-styles/plain-technical-english.md"

settings="$target/settings.json"
# Back up once, before our hooks first land in the file.
if [ -f "$settings" ] && [ ! -f "$settings.acc-backup" ] && ! grep -q 'ai-coding-config:' "$settings"; then
  if dry; then say "would back up $settings to $settings.acc-backup"
  else cp "$settings" "$settings.acc-backup"; say "backup    $settings.acc-backup"; fi
  record backup "$settings.acc-backup"
fi
render_to settings settings-merge --settings "$settings" --hooks "$root/hooks/hooks.json" --root "$root" --output-style "Plain Technical English"

# AGENTS.md carries the instructions. CLAUDE.md imports it, because Claude Code reads only
# CLAUDE.md when both exist, and reads nothing from ~/.claude/AGENTS.md on its own.
# Globally AGENTS.md is a link to this config. In a project it is a copied block, because
# Claude Code does not follow a project import that points outside the project.
if [ "$scope" = project ]; then
  instructions_dir=$project
  render_to managed-block managed-block --root "$root" --out "$instructions_dir/AGENTS.md"
else
  instructions_dir=$target
  place "$root/AGENTS.md" "$instructions_dir/AGENTS.md"
fi
render_to managed-block managed-block --root "$root" --out "$instructions_dir/CLAUDE.md" --import AGENTS.md

# --- git hooks ---------------------------------------------------------------
if [ "$scope" = project ] && [ "$git_hooks" = 1 ]; then
  git_dir=$(cd "$project" && git rev-parse --git-dir 2>/dev/null)
  hooks_path=$(cd "$project" && git config --get core.hooksPath 2>/dev/null)
  if [ -z "$git_dir" ]; then
    say "note: $project is not a git repository, so no git hooks were installed."
  elif [ -n "$hooks_path" ]; then
    say "note: core.hooksPath is set to $hooks_path, so the git hooks were left to that tool."
  else
    case "$git_dir" in /*) ;; *) git_dir="$project/$git_dir" ;; esac
    for hook in pre-commit pre-push; do
      place "$root/git-hooks/$hook" "$git_dir/hooks/$hook"
    done
    if dry; then say "would set git config ai-coding-config.gate"
    else (cd "$project" && git config ai-coding-config.gate "$root/hooks/verify-gate.sh"); say "git config ai-coding-config.gate set"; fi
    record git-config ai-coding-config.gate
  fi
fi

# --- manifest ----------------------------------------------------------------
manifest="$target/acc-manifest.json"
{ printf '%s' "$manifest_entries"; cat "$entries_file"; } | sort -u | \
  python3 "$render" manifest $(dry && printf -- '--dry-run') --out "$manifest" --root "$root" --scope "$scope" --target "$target" --mode "$mode" | while IFS= read -r line; do say "$line"; done
rm -f "$entries_file"
say ''
say "Done. Skipped lines name files that already existed; remove them and rerun if they should be replaced."
exit 0
