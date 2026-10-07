#!/usr/bin/env bash
# Test suite for ai-coding-config. Sends fixture JSON to each hook and checks what it
# prints, exercises the libraries, the git hooks, render.py, and the installer, and
# checks the invariants CONTRIBUTING.md names. Runs with bash 3.2.
#
#   tests/run-tests.sh            run everything
#   tests/run-tests.sh -v         also print each passing check

root=$(cd "$(dirname "$0")/.." && pwd -P)
verbose=0
[ "${1:-}" = -v ] && verbose=1

pass=0
fail=0
failed_names=''
work=$(mktemp -d "${TMPDIR:-/tmp}/acc-tests.XXXXXX")
trap 'rm -rf "$work"' EXIT
export AI_CODING_CONFIG_SKIP_VERIFY=0
export HOME="$work/home"
mkdir -p "$HOME"
unset TMPDIR

ok() { pass=$((pass + 1)); [ "$verbose" = 1 ] && printf 'ok   %s\n' "$1"; return 0; }
bad() { fail=$((fail + 1)); failed_names="$failed_names
  $1"; printf 'FAIL %s\n     %s\n' "$1" "$2"; }

expect_eq() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$2], got [$3]"; fi; }
expect_contains() { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" "expected to contain [$3], got [$2]" ;; esac; }
expect_empty() { if [ -z "$2" ]; then ok "$1"; else bad "$1" "expected nothing, got [$2]"; fi; }
expect_not_contains() { case "$2" in *"$3"*) bad "$1" "did not expect [$3] in [$2]" ;; *) ok "$1" ;; esac; }
expect_file() { if [ -e "$2" ] || [ -L "$2" ]; then ok "$1"; else bad "$1" "missing $2"; fi; }
expect_no_file() { if [ -e "$2" ] || [ -L "$2" ]; then bad "$1" "unexpected $2"; else ok "$1"; fi; }
is_json() { printf '%s' "$1" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; }
expect_json() { if is_json "$2"; then ok "$1"; else bad "$1" "not JSON: [$2]"; fi; }
json_field() { printf '%s' "$1" | python3 -c '
import json, sys
d = json.load(sys.stdin)
for k in sys.argv[1:]:
    d = d[int(k)] if isinstance(d, list) else d[k]
print(d if isinstance(d, str) else json.dumps(d))' "${@:2}" 2>/dev/null; }
to_json_string() { python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"; }

section() { printf -- '-- %s\n' "$1"; }

# ---------------------------------------------------------------------------
section "repository invariants"

shell_files=$(find "$root/hooks" "$root/install" "$root/git-hooks" "$root/tests" -type f \( -name '*.sh' -o -name 'pre-*' \))
for pattern in 'declare -A' 'mapfile' 'readarray' 'sed -i' 'readlink -f' '\${[a-zA-Z_]*,,}' '\${[a-zA-Z_]*\^\^}' '|&' 'read -N'; do
  # The line in this file that lists the patterns is not a use of them.
  hits=$(printf '%s\n' "$shell_files" | xargs grep -n -- "$pattern" 2>/dev/null | grep -v 'for pattern in' | cut -d: -f1 | sort -u | sed "s|$root/||")
  expect_empty "bash 3.2: no '$pattern'" "$hits"
done

for rule in "$root"/rules/*.md; do
  name=$(basename "$rule")
  front=$(sed -n '2,/^---$/p' "$rule")
  # A rule without paths loads on every turn; only the core rule is allowed that.
  if [ "$name" != 00-core-engineering.md ]; then
    expect_contains "rule $name declares paths" "$front" "paths:"
  fi
done

for skill in "$root"/skills/*/SKILL.md; do
  dir=$(basename "$(dirname "$skill")")
  name=$(sed -n 's/^name: *//p' "$skill" | head -1)
  expect_eq "skill $dir: name matches directory" "$dir" "$name"
  if grep -q '^disable-model-invocation: true' "$skill"; then
    case "$dir" in
      commit|pr-create) ok "skill $dir: person-started by design" ;;
      *) bad "skill $dir: disable-model-invocation" "only commit and pr-create carry it" ;;
    esac
  fi
done
expect_eq "commit skill is person-started" 1 "$(grep -c '^disable-model-invocation: true' "$root/skills/commit/SKILL.md")"
expect_eq "pr-create skill is person-started" 1 "$(grep -c '^disable-model-invocation: true' "$root/skills/pr-create/SKILL.md")"

hooks_json=$(cat "$root/hooks/hooks.json")
expect_json "hooks.json is valid JSON" "$hooks_json"
for event in SessionStart PreToolUse PostToolUse Stop; do
  expect_contains "hooks.json registers $event" "$(json_field "$hooks_json" hooks)" "\"$event\""
done
expect_eq "hooks.json SessionStart matcher" "startup|clear|compact" "$(json_field "$hooks_json" hooks SessionStart 0 matcher)"
expect_eq "hooks.json Stop timeout" "600" "$(json_field "$hooks_json" hooks Stop 0 hooks 0 timeout)"
commands=$(printf '%s' "$hooks_json" | python3 -c '
import json, sys
d = json.load(sys.stdin)["hooks"]
for groups in d.values():
    for g in groups:
        for h in g["hooks"]:
            print(h["command"])')
for cmd in $commands; do
  case "$cmd" in
    __ACC_ROOT__/hooks/*) ok "hooks.json path uses __ACC_ROOT__: $cmd" ;;
    *) bad "hooks.json path $cmd" "must be __ACC_ROOT__/hooks/<script>" ;;
  esac
  script="$root/hooks/${cmd#__ACC_ROOT__/hooks/}"
  if [ -x "$script" ]; then ok "hook script exists and is executable: $(basename "$script")"; else bad "hook script $script" "missing or not executable"; fi
done
for script in guard-dangerous-commands validate-commit-msg guard-secrets mark-dirty verify-gate session-start; do
  expect_contains "hooks.json registers $script" "$commands" "$script.sh"
done
tagged=$(printf '%s' "$hooks_json" | python3 -c '
import json, sys
d = json.load(sys.stdin)["hooks"]
print(all(h.get("statusMessage","").startswith("ai-coding-config:") for gs in d.values() for g in gs for h in g["hooks"]))')
expect_eq "hooks.json: every hook is tagged through statusMessage" True "$tagged"

# ---------------------------------------------------------------------------
section "hooks/lib/json.sh"
. "$root/hooks/lib/json.sh"
doc='{"tool_name":"Bash","tool_input":{"command":"git push","n":3,"ok":true,"nil":null,"edits":[{"new_string":"a\"b"},{"new_string":"l1\nl2"}]}}'
expect_eq "json_get string" "Bash" "$(json_get "$doc" tool_name)"
expect_eq "json_get nested string" "git push" "$(json_get "$doc" tool_input command)"
expect_eq "json_get number" "3" "$(json_get "$doc" tool_input n)"
expect_eq "json_get boolean" "true" "$(json_get "$doc" tool_input ok)"
expect_empty "json_get null" "$(json_get "$doc" tool_input nil)"
expect_empty "json_get missing key" "$(json_get "$doc" tool_input missing deeper)"
expect_eq "json_get array index" 'a"b' "$(json_get "$doc" tool_input edits 0 new_string)"
expect_eq "json_get multi-line string" "l1
l2" "$(json_get "$doc" tool_input edits 1 new_string)"
expect_eq "json_get compound prints JSON" '[{"new_string":"a\"b"},{"new_string":"l1\nl2"}]' "$(json_get "$doc" tool_input edits)"
expect_empty "json_get on invalid input" "$(json_get 'not json' a)"
expect_empty "json_get on empty input" "$(json_get '' a)"
expect_eq "json_backend names a backend" 0 "$(case "$(json_backend)" in jq|python3|node) echo 0 ;; *) echo 1 ;; esac)"
if command -v node >/dev/null 2>&1; then
  out=$(bash -c ". '$root/hooks/lib/json.sh'; json_backend() { echo node; }; json_get '$doc' tool_input edits 1 new_string")
  expect_eq "json_get via node backend" "l1
l2" "$out"
fi
out=$(bash -c ". '$root/hooks/lib/json.sh'; json_backend() { echo none; }; json_get '$doc' tool_name; echo \"rc=\$?\"")
expect_eq "json_get with no backend prints nothing, exit 0" "rc=0" "$out"
expect_eq "json_escape" '"a\\b\"c\nd"' "$(json_escape 'a\b"c
d')"
expect_json "hook_deny is JSON" "$(hook_deny 'why "quoted"')"
expect_eq "hook_deny decision" deny "$(json_field "$(hook_deny why)" hookSpecificOutput permissionDecision)"
expect_eq "hook_block_stop decision" block "$(json_field "$(hook_block_stop why)" decision)"
expect_eq "hook_context event" SessionStart "$(json_field "$(hook_context SessionStart text)" hookSpecificOutput hookEventName)"

# ---------------------------------------------------------------------------
section "hooks/lib/shell-words.sh"
. "$root/hooks/lib/shell-words.sh"
expect_eq "words split on space" "a
b" "$(shell_segments 'a b')"
expect_eq "double quotes group" "echo
git push --force" "$(shell_segments 'echo "git push --force"')"
expect_eq "single quotes group" "rm -rf /" "$(shell_segments "'rm -rf /'")"
expect_eq "&& separates" "a
--
b" "$(shell_segments 'a && b')"
expect_eq "pipe separates" "a
--
b" "$(shell_segments 'a | b')"
expect_eq "newline separates" "a
--
b" "$(shell_segments 'a
b')"
expect_eq "backslash escapes a space" "a b" "$(shell_segments 'a\ b')"
expect_eq "escaped quote inside double quotes" 'say "hi"' "$(shell_segments '"say \"hi\""')"

# ---------------------------------------------------------------------------
section "hooks/lib/state.sh"
. "$root/hooks/lib/state.sh"
repo="$work/state-repo"; mkdir -p "$repo"; (cd "$repo" && git init -q .)
out=$(cd "$repo" && state_dir)
expect_eq "state_dir inside git" "$repo/.git/ai-coding-config" "$out"
out=$(cd "$work" && state_dir)
expect_contains "state_dir outside git is under tmp and keyed" "$out" "/ai-coding-config-"
out=$(cd "$repo" && state_append_unique t a && state_append_unique t b && state_append_unique t a && state_read t)
expect_eq "state_append_unique dedupes" "a
b" "$out"
out=$(cd "$repo" && state_write t z && state_read t)
expect_eq "state_write replaces" z "$out"
out=$(cd "$repo" && state_clear t && state_read t)
expect_empty "state_clear removes" "$out"

# ---------------------------------------------------------------------------
section "hooks/lib/detect-toolchain.sh"
detect="$root/hooks/lib/detect-toolchain.sh"
fx="$work/fixtures"
mk() { mkdir -p "$fx/$1"; }
mk js; printf '{"scripts":{"test":"vitest run","lint":"eslint ."},"devDependencies":{"typescript":"^5","prettier":"^3"}}' > "$fx/js/package.json"; touch "$fx/js/tsconfig.json" "$fx/js/pnpm-lock.yaml"
out=$("$detect" "$fx/js")
expect_contains "package.json test via pnpm" "$out" "test	pnpm run test	0"
expect_contains "package.json lint" "$out" "lint	pnpm run lint	0"
expect_contains "tsconfig gives typecheck" "$out" "typecheck	npx tsc --noEmit	0"
expect_contains "prettier takes file args" "$out" "format	npx prettier --check	1"
mk js2; printf '{"scripts":{"test":"echo \\"Error: no test specified\\" && exit 1"}}' > "$fx/js2/package.json"
out=$("$detect" "$fx/js2")
expect_not_contains "npm default test script is ignored" "$out" "npm test"
expect_contains "nothing found gives a note" "$out" "note	no verification commands"
mk py; printf '[tool.ruff]\nline-length=100\n[tool.mypy]\nstrict=true\n' > "$fx/py/pyproject.toml"; touch "$fx/py/uv.lock"; mkdir -p "$fx/py/tests"
out=$("$detect" "$fx/py")
expect_contains "ruff lint with file args under uv" "$out" "lint	uv run ruff check	1"
expect_contains "ruff format" "$out" "format	uv run ruff format --check	1"
expect_contains "mypy typecheck" "$out" "typecheck	uv run mypy .	0"
expect_contains "pytest" "$out" "test	uv run pytest	0"
mk go; echo 'module x' > "$fx/go/go.mod"
out=$("$detect" "$fx/go")
expect_contains "go test" "$out" "test	go test ./...	0"
expect_contains "go vet" "$out" "lint	go vet ./...	0"
expect_contains "gofmt check takes files" "$out" 'gofmt -l "$@"'
mk rs; echo '[package]' > "$fx/rs/Cargo.toml"
out=$("$detect" "$fx/rs")
expect_contains "cargo test" "$out" "test	cargo test	0"
expect_contains "cargo fmt" "$out" "format	cargo fmt --check	0"
mk jvm; touch "$fx/jvm/pom.xml" "$fx/jvm/build.gradle"
out=$("$detect" "$fx/jvm")
expect_contains "maven" "$out" "test	mvn -q -B test	0"
expect_contains "gradle" "$out" "test	gradle test	0"
mk make; printf 'lint:\n\techo\ntest: lint\n\techo\nfmt:\n\techo\n' > "$fx/make/Makefile"
out=$("$detect" "$fx/make")
expect_contains "make lint" "$out" "lint	make lint	0"
expect_contains "make test" "$out" "test	make test	0"
expect_contains "make fmt as format" "$out" "format	make fmt	0"
mk cfg; echo '{"test":"bash t.sh","lint":"","gate":["test"],"timeoutSeconds":5}' > "$fx/cfg/.agentconfig.json"; printf '[tool.ruff]\n' > "$fx/cfg/pyproject.toml"
out=$("$detect" "$fx/cfg")
expect_contains ".agentconfig.json test wins" "$out" "test	bash t.sh	0"
expect_not_contains ".agentconfig.json empty lint pins to none" "$out" "ruff check"
expect_contains ".agentconfig.json leaves format to detection" "$out" "ruff format --check"
expect_contains ".agentconfig.json gate note" "$out" "note	gate: test"
mk skip; echo '{"skip":true}' > "$fx/skip/.agentconfig.json"; touch "$fx/skip/go.mod"
out=$("$detect" "$fx/skip")
expect_eq "skip emits one note only" "note	skip: .agentconfig.json turns the gate off	0" "$out"
expect_eq "missing directory exits 0 silently" "rc=0 []" "$(o=$("$detect" /nonexistent-dir); echo "rc=$? [$o]")"

# ---------------------------------------------------------------------------
section "hooks/guard-dangerous-commands.sh"
proj="$work/proj"; mkdir -p "$proj/sub"; (cd "$proj" && git init -q .)
guard() { printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":%s}}' "$proj" "$(to_json_string "$1")" | "$root/hooks/guard-dangerous-commands.sh"; }
blocks() { out=$(guard "$2"); if [ "$(json_field "$out" hookSpecificOutput permissionDecision)" = deny ]; then ok "blocks: $1"; else bad "blocks: $1" "got [$out]"; fi; }
allows() { out=$(guard "$2"); expect_empty "allows: $1" "$out"; }
blocks "git push --force" 'git push --force origin main'
blocks "git push -f" 'git push -f'
blocks "git push --force-with-lease" 'git push --force-with-lease'
blocks "git -C dir push -f" 'git -C /x push -f'
blocks "git reset --hard" 'git reset --hard HEAD~1'
blocks "git clean -fdx" 'git clean -fdx'
blocks "git clean --force" 'git clean --force'
blocks "git branch -D" 'git branch -D feature'
blocks "git branch --delete --force" 'git branch --delete --force feature'
blocks "rm -rf outside root" 'rm -rf /tmp/elsewhere'
blocks "rm -rf parent escape" 'rm -rf ../sibling'
blocks "rm -rf tilde" 'rm -rf ~/.cache'
blocks "rm -rf \$HOME" 'rm -rf "$HOME/x"'
blocks "rm -r -f /" 'rm -r -f /'
blocks "sudo rm -rf" 'sudo rm -rf /var/log'
blocks "env assignment then git push -f" 'FOO=1 git push -f'
blocks "chained after &&" 'git add . && git commit -m "x" && git push --force'
allows "git push" 'git push origin main'
allows "git reset --soft" 'git reset --soft HEAD~1'
allows "git clean -n" 'git clean -n'
allows "git branch -d" 'git branch -d feature'
allows "rm -rf inside root" 'rm -rf build/'
allows "rm -rf dot" 'rm -rf .'
allows "rm -rf absolute inside root" "rm -rf $proj/sub"
allows "rm -f without -r" 'rm -f file.txt'
allows "unknown variable fails open" 'rm -rf $SOMEVAR/x'
allows "echo of a dangerous string" 'echo "git push --force"'
allows "grep of a dangerous string" 'grep -r "rm -rf /" .'
allows "git log mentioning force" 'git log --grep="force"'
allows "cd then rm inside" "cd $proj && rm -rf stuff"
expect_eq "empty input exits 0 silently" "rc=0 []" "$(o=$(echo '{}' | "$root/hooks/guard-dangerous-commands.sh"); echo "rc=$? [$o]")"
expect_eq "garbage input exits 0 silently" "rc=0 []" "$(o=$(echo 'garbage' | "$root/hooks/guard-dangerous-commands.sh"); echo "rc=$? [$o]")"
out=$(guard 'git push -f')
expect_json "deny output is JSON" "$out"
expect_eq "deny output names the event" PreToolUse "$(json_field "$out" hookSpecificOutput hookEventName)"

# ---------------------------------------------------------------------------
section "hooks/validate-commit-msg.sh"
vcm() { printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":%s}}' "$proj" "$(to_json_string "$1")" | "$root/hooks/validate-commit-msg.sh"; }
rejects() { out=$(vcm "$2"); if [ "$(json_field "$out" hookSpecificOutput permissionDecision)" = deny ]; then ok "rejects: $1"; else bad "rejects: $1" "got [$out]"; fi; }
accepts() { out=$(vcm "$2"); expect_empty "accepts: $1" "$out"; }
accepts "type(scope): subject" 'git commit -m "feat(upload): retry once on timeout"'
accepts "type: subject" 'git commit -m "docs: add install steps"'
accepts "breaking change marker" 'git commit -m "feat(api)!: drop v1"'
accepts "--message=" 'git commit --message="docs(readme): add install"'
accepts "-m glued" 'git commit -m"ci: x"'
accepts "two -m, first is subject" 'git add a && git commit -m "chore: tidy" -m "Body text."'
accepts "multi-line message checks first line" 'git commit -m "feat(x): first line
Second line."'
accepts "merge" 'git commit -m "Merge branch main into feature"'
accepts "revert" 'git commit -m "Revert \"feat(x): y\""'
accepts "fixup flag" 'git commit --fixup HEAD'
accepts "squash flag" 'git commit --squash=HEAD'
accepts "fixup! subject" 'git commit -m "fixup! feat(x): y"'
accepts "-F file" 'git commit -F msg.txt'
accepts "amend without -m" 'git commit --amend --no-edit'
accepts "echo mentioning git commit" 'echo "git commit -m WIP"'
accepts "not a commit" 'git status'
rejects "no type" 'git commit -m "Fixed a bug"'
rejects "upper case subject" 'git commit -m "fix: Retry"'
rejects "ticket key prefix" 'git commit -m "PROJ-123 fix(x): a"'
rejects "trailing period" 'git commit -m "fix(upload): retry once on timeout."'
rejects "unknown type" 'git commit -m "feature(x): add"'
rejects "scope not kebab" 'git commit -m "fix(Upload): a"'
rejects "over 72 characters" "git commit -m \"feat(x): $(printf 'a%.0s' $(seq 1 70))\""
rejects "WIP" 'git commit -m "WIP"'
rejects "commit after other commands" 'git add . && git commit -m "bad subject"'
expect_eq "empty input exits 0 silently" "rc=0 []" "$(o=$(echo '{}' | "$root/hooks/validate-commit-msg.sh"); echo "rc=$? [$o]")"

# ---------------------------------------------------------------------------
section "hooks/guard-secrets.sh"
sec() { printf '{"tool_name":"Write","cwd":"%s","tool_input":{"file_path":"config.py","content":%s}}' "$proj" "$(to_json_string "$1")" | "$root/hooks/guard-secrets.sh"; }
denies() { out=$(sec "$2"); if [ "$(json_field "$out" hookSpecificOutput permissionDecision)" = deny ]; then ok "denies: $1"; else bad "denies: $1" "got [$out]"; fi; }
passes() { out=$(sec "$2"); expect_empty "passes: $1" "$out"; }
# Fixture secrets are assembled at runtime so this file never carries one.
aws="AK""IA""IOSFODNN7EXAMPLE"
gh="gh""p_$(printf 'a%.0s' $(seq 1 36))"
slack="xo""xb-$(printf '1%.0s' $(seq 1 12))-abcdef"
stripe="sk""_live_$(printf 'A%.0s' $(seq 1 30))"
google="AI""za$(printf 'b%.0s' $(seq 1 35))"
anthropic="sk""-ant-api03-$(printf 'c%.0s' $(seq 1 60))"
pem="-----BEGIN"" RSA PRIVATE KEY-----"
denies "aws access key" "key = \"$aws\""
denies "github token" "token: $gh"
denies "slack token" "SLACK=$slack"
denies "stripe live key" "const k = '$stripe'"
denies "google api key" "$google"
denies "anthropic key" "ANTHROPIC_API_KEY=$anthropic"
denies "private key block" "$pem
MIIE"
denies "literal password" 'password = "hunter2hunter2"'
denies "literal api_key" 'api_key: "d41d8cd98f00b204e9800998"'
denies "json client_secret" '{"client_secret": "s3cr3tvalue-abcdef"}'
denies "literal token in yaml" 'auth_token: "k9f8d7s6a5f4d3s2a1"'
passes "placeholder angle brackets" 'password = "<your-password>"'
passes "placeholder xxx" 'api_key = "xxxxxxxxxxxxxxxx"'
passes "placeholder changeme" 'secret: "changeme123"'
passes "placeholder example" 'password: "example-password"'
passes "placeholder dummy" 'password = "dummy-password-1"'
passes "env lookup python" 'password = os.environ["DB_PASSWORD"]'
passes "env lookup node" 'const key = process.env.API_KEY'
passes "shell expansion" 'API_KEY="${API_KEY}"'
passes "template braces" 'token: "{{ vault_token }}"'
passes "short value" 'token = "abc"'
passes "name only" 'token = get_token()'
passes "plain code" 'def f():
    return 1'
passes "empty content" ''
out=$(printf '{"tool_name":"Edit","tool_input":{"file_path":"a.ts","old_string":"x","new_string":"const k = process.env.API_KEY"}}' | "$root/hooks/guard-secrets.sh")
expect_empty "Edit new_string env lookup passes" "$out"
out=$(printf '{"tool_name":"Edit","tool_input":{"file_path":"a.ts","old_string":"x","new_string":%s}}' "$(to_json_string "const apiKey = '$stripe'")" | "$root/hooks/guard-secrets.sh")
expect_eq "Edit new_string key is denied" deny "$(json_field "$out" hookSpecificOutput permissionDecision)"
out=$(printf '{"tool_name":"MultiEdit","tool_input":{"file_path":"a.ts","edits":[{"old_string":"x","new_string":"ok"},{"old_string":"y","new_string":%s}]}}' "$(to_json_string "client_secret = 'realsecretvalue99'")" | "$root/hooks/guard-secrets.sh")
expect_eq "MultiEdit second edit is denied" deny "$(json_field "$out" hookSpecificOutput permissionDecision)"
expect_contains "deny names the file" "$out" "a.ts"
expect_eq "empty input exits 0 silently" "rc=0 []" "$(o=$(echo '{}' | "$root/hooks/guard-secrets.sh"); echo "rc=$? [$o]")"

# ---------------------------------------------------------------------------
section "hooks/mark-dirty.sh"
mark() { printf '{"tool_name":"Write","cwd":"%s","tool_input":{"file_path":"%s"}}' "$1" "$2" | "$root/hooks/mark-dirty.sh"; }
rm -rf "$proj/.git/ai-coding-config"
out=$(mark "$proj" "$proj/a.txt"); expect_empty "mark-dirty prints nothing" "$out"
mark "$proj" "$proj/a.txt"; mark "$proj" "b.txt"
expect_eq "mark-dirty records each path once" "$proj/a.txt
b.txt" "$(cat "$proj/.git/ai-coding-config/dirty-files")"
expect_eq "mark-dirty records nothing else" 1 "$(ls "$proj/.git/ai-coding-config" | wc -l | tr -d ' ')"
expect_eq "mark-dirty without a path exits 0" "rc=0" "$(echo '{}' | "$root/hooks/mark-dirty.sh"; echo "rc=$?")"

# ---------------------------------------------------------------------------
section "hooks/session-start.sh"
out=$(printf '{"hook_event_name":"SessionStart","source":"startup","cwd":"%s"}' "$fx/js" | "$root/hooks/session-start.sh")
expect_json "session-start prints JSON" "$out"
ctx=$(json_field "$out" hookSpecificOutput additionalContext)
expect_contains "session-start lists the test command" "$ctx" "test: pnpm run test"
expect_contains "session-start lists the lint command" "$ctx" "lint: pnpm run lint"
out=$(printf '{"source":"startup","cwd":"%s"}' "$fx/empty-none" | "$root/hooks/session-start.sh")
mkdir -p "$fx/empty-none"
out=$(printf '{"source":"startup","cwd":"%s"}' "$fx/empty-none" | "$root/hooks/session-start.sh")
expect_contains "session-start says when nothing is detected" "$(json_field "$out" hookSpecificOutput additionalContext)" "no commands detected"

# ---------------------------------------------------------------------------
section "hooks/verify-gate.sh"
gate="$root/hooks/verify-gate.sh"
g="$work/gate"; mkdir -p "$g"; (cd "$g" && git init -q . && git config user.email t@t && git config user.name t)
echo '{"test":"bash check.sh","lint":"bash lint.sh","timeoutSeconds":5}' > "$g/.agentconfig.json"
echo 'exit 0' > "$g/check.sh"; printf 'echo "lint args: $@"\nexit 0\n' > "$g/lint.sh"
stop() { printf '{"hook_event_name":"Stop","cwd":"%s","stop_hook_active":false}' "$g" | "$gate"; }
dirty() { printf '{"cwd":"%s","tool_input":{"file_path":"%s"}}' "$g" "$g/check.sh" | "$root/hooks/mark-dirty.sh"; }
state="$g/.git/ai-coding-config"
expect_eq "stop with nothing dirty is silent, exit 0" "rc=0 []" "$(o=$(stop); echo "rc=$? [$o]")"
dirty
expect_eq "stop with passing commands is silent" "rc=0 []" "$(o=$(stop); echo "rc=$? [$o]")"
expect_no_file "passing run clears the dirty list" "$state/dirty-files"
echo 'echo boom; exit 3' > "$g/check.sh"; dirty
out=$(stop)
expect_json "failing run prints JSON" "$out"
expect_eq "failing run blocks the stop" block "$(json_field "$out" decision)"
expect_contains "block reason names the command" "$(json_field "$out" reason)" "bash check.sh"
expect_contains "block reason carries the output" "$(json_field "$out" reason)" "boom"
expect_contains "block reason counts attempts" "$(json_field "$out" reason)" "attempt 1 of 3"
expect_file "failing run keeps the dirty list" "$state/dirty-files"
out=$(stop); expect_contains "second attempt on the same tree" "$(json_field "$out" reason)" "attempt 2 of 3"
out=$(stop)
expect_json "third attempt prints JSON" "$out"
expect_empty "third attempt on an unchanged tree releases" "$(json_field "$out" decision)"
expect_contains "release explains itself" "$(json_field "$out" hookSpecificOutput additionalContext)" "releasing"
expect_no_file "release clears the dirty list" "$state/dirty-files"
dirty; stop >/dev/null; echo 'echo boom2; exit 1' > "$g/check.sh"
out=$(stop); expect_contains "a changed tree resets the attempt count" "$(json_field "$out" reason)" "attempt 1 of 3"
expect_eq "AI_CODING_CONFIG_SKIP_VERIFY=1 skips the gate" "rc=0 []" "$(o=$(AI_CODING_CONFIG_SKIP_VERIFY=1 stop); echo "rc=$? [$o]")"
rm -rf "$state"
out=$(cd "$g" && "$gate" --files check.sh 2>&1); rc=$?
expect_eq "direct mode fails on a failing command" 1 "$rc"
expect_contains "direct mode prints the output" "$out" "boom2"
expect_contains "direct mode names the failure" "$out" "verify-gate: failed"
echo 'exit 0' > "$g/check.sh"
out=$(cd "$g" && "$gate" --files check.sh lint.sh 2>&1); rc=$?
expect_eq "direct mode passes" 0 "$rc"
out=$(cd "$g" && "$gate" --files 2>&1); rc=$?
expect_eq "direct mode with no files runs the whole tree" 0 "$rc"
expect_eq "direct mode honours the skip variable" "0" "$(echo 'exit 2' > "$g/check.sh"; cd "$g" && AI_CODING_CONFIG_SKIP_VERIFY=1 "$gate" --files check.sh >/dev/null 2>&1; echo $?)"
echo 'exit 0' > "$g/check.sh"
echo '{"test":"exit 1","lint":"bash lint.sh","gate":["lint"]}' > "$g/.agentconfig.json"; dirty
expect_eq "gate key limits which categories block" "rc=0 []" "$(o=$(stop); echo "rc=$? [$o]")"
echo '{"test":"sleep 3","timeoutSeconds":1}' > "$g/.agentconfig.json"; dirty
out=$(stop); expect_eq "timeoutSeconds kills a slow command and blocks" block "$(json_field "$out" decision)"
rm -rf "$state"
# A tool that takes file args gets the dirty paths appended; a fake ruff records them.
fakebin="$work/bin"; mkdir -p "$fakebin"; printf '#!/bin/sh\necho "ruff got: $*" >> "%s/ruff.log"\nexit 0\n' "$g" > "$fakebin/ruff"; chmod +x "$fakebin/ruff"
rm "$g/.agentconfig.json"; printf '[tool.ruff]\n' > "$g/pyproject.toml"; dirty
PATH="$fakebin:$PATH" stop >/dev/null
expect_contains "file-taking commands get the dirty paths" "$(cat "$g/ruff.log" 2>/dev/null)" "check.sh"
rm -f "$g/ruff.log"; (cd "$g" && PATH="$fakebin:$PATH" "$gate" --files >/dev/null 2>&1)
expect_contains "file-taking commands get . without files" "$(cat "$g/ruff.log" 2>/dev/null)" "ruff got: check ."
dirty
out=$(PATH=/usr/bin:/bin stop); rc=$?
expect_eq "a missing tool is skipped, not a block" "rc=0 []" "rc=$rc [$out]"
rm -f "$g/pyproject.toml"; rm -rf "$state"

# ---------------------------------------------------------------------------
section "git-hooks"
echo '{"test":"bash check.sh","lint":"bash lint.sh"}' > "$g/.agentconfig.json"; echo 'exit 0' > "$g/check.sh"
(cd "$g" && git config --unset ai-coding-config.gate 2>/dev/null; true)
expect_eq "pre-commit without the gate config exits 0" 0 "$(cd "$g" && "$root/git-hooks/pre-commit" >/dev/null 2>&1; echo $?)"
(cd "$g" && git config ai-coding-config.gate "$gate")
expect_eq "pre-commit with nothing staged exits 0" 0 "$(cd "$g" && "$root/git-hooks/pre-commit" >/dev/null 2>&1; echo $?)"
(cd "$g" && git add check.sh lint.sh .agentconfig.json)
expect_eq "pre-commit passes on a green tree" 0 "$(cd "$g" && "$root/git-hooks/pre-commit" >/dev/null 2>&1; echo $?)"
echo 'exit 2' > "$g/check.sh"; (cd "$g" && git add check.sh)
expect_eq "pre-commit fails on a red tree" 1 "$(cd "$g" && "$root/git-hooks/pre-commit" >/dev/null 2>&1; echo $?)"
expect_eq "pre-push fails on a red tree" 1 "$(cd "$g" && "$root/git-hooks/pre-push" >/dev/null 2>&1; echo $?)"
echo 'exit 0' > "$g/check.sh"; (cd "$g" && git add check.sh)
expect_eq "pre-push passes on a green tree" 0 "$(cd "$g" && "$root/git-hooks/pre-push" >/dev/null 2>&1; echo $?)"
expect_eq "pre-push above the cap still runs" 0 "$(cd "$g" && AI_CODING_CONFIG_PUSH_CAP=1 "$root/git-hooks/pre-push" >/dev/null 2>&1; echo $?)"
echo 'exit 2' > "$g/check.sh"
expect_eq "pre-push honours the skip variable" 0 "$(cd "$g" && AI_CODING_CONFIG_SKIP_VERIFY=1 "$root/git-hooks/pre-push" >/dev/null 2>&1; echo $?)"

# ---------------------------------------------------------------------------
section "install/lib/render.py"
render="$root/install/lib/render.py"
r="$work/render"; mkdir -p "$r"
python3 "$render" settings-merge --settings "$r/settings.json" --hooks "$root/hooks/hooks.json" --root "$root" --output-style "Plain Technical English" >/dev/null
s=$(cat "$r/settings.json")
expect_json "settings-merge writes JSON" "$s"
expect_eq "settings-merge substitutes __ACC_ROOT__" "$root/hooks/verify-gate.sh" "$(json_field "$s" hooks Stop 0 hooks 0 command)"
expect_eq "settings-merge sets outputStyle when absent" "Plain Technical English" "$(json_field "$s" outputStyle)"
printf '{"permissions":{"allow":["Bash(ls:*)"]},"outputStyle":"Concise","hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"echo mine"}]}],"Stop":[{"hooks":[{"type":"command","command":"/old/verify-gate.sh","statusMessage":"ai-coding-config: old"}]}]}}' > "$r/s2.json"
python3 "$render" settings-merge --settings "$r/s2.json" --hooks "$root/hooks/hooks.json" --root "$root" --output-style "Plain Technical English" >/dev/null
s=$(cat "$r/s2.json")
expect_eq "settings-merge keeps other settings" '["Bash(ls:*)"]' "$(json_field "$s" permissions allow)"
expect_eq "settings-merge keeps an existing outputStyle" Concise "$(json_field "$s" outputStyle)"
expect_eq "settings-merge keeps a foreign hook group" "echo mine" "$(json_field "$s" hooks PreToolUse 0 hooks 0 command)"
expect_eq "settings-merge replaces a stale group of ours" 1 "$(printf '%s' "$s" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)["hooks"]["Stop"]))')"
before=$(cat "$r/s2.json")
out=$(python3 "$render" settings-merge --settings "$r/s2.json" --hooks "$root/hooks/hooks.json" --root "$root")
expect_contains "settings-merge is idempotent" "$out" "unchanged"
expect_eq "settings-merge idempotent content" "$before" "$(cat "$r/s2.json")"
out=$(python3 "$render" settings-merge --dry-run --settings "$r/none.json" --hooks "$root/hooks/hooks.json" --root "$root")
expect_contains "settings-merge dry run reports" "$out" "would write"
expect_no_file "settings-merge dry run writes nothing" "$r/none.json"
python3 "$render" output-style --root "$root" --out "$r/style.md" >/dev/null
expect_eq "output style name" "name: Plain Technical English" "$(sed -n '2p' "$r/style.md")"
expect_contains "output style keeps coding instructions" "$(cat "$r/style.md")" "keep-coding-instructions: true"
expect_contains "output style carries the body" "$(cat "$r/style.md")" "No semicolons."
python3 "$render" managed-block --root "$root" --out "$r/CLAUDE.md" >/dev/null
expect_contains "managed block created in a new file" "$(cat "$r/CLAUDE.md")" "<!-- ai-coding-config:begin -->"
expect_eq "a new file holds only the block" "<!-- ai-coding-config:begin -->" "$(head -1 "$r/CLAUDE.md")"
printf '# Mine\n\n@AGENTS.md\n' > "$r/C2.md"
out=$(python3 "$render" managed-block --root "$root" --out "$r/C2.md" --import AGENTS.md)
expect_contains "an existing import of AGENTS.md is left alone" "$out" "already imports AGENTS.md"
expect_eq "no second import is added" 1 "$(grep -c '^@AGENTS.md' "$r/C2.md")"
python3 "$render" managed-block --root "$root" --out "$r/C3.md" --import AGENTS.md >/dev/null
expect_eq "a created CLAUDE.md holds just the import" "<!-- ai-coding-config:begin -->
<!-- generated by ai-coding-config; edits are overwritten on the next install -->
@AGENTS.md
<!-- ai-coding-config:end -->" "$(cat "$r/C3.md")"
expect_contains "managed block carries the non-negotiables" "$(cat "$r/CLAUDE.md")" "Non-negotiables"
printf '# Mine\n\nkeep this\n' > "$r/A2.md"
python3 "$render" managed-block --root "$root" --out "$r/A2.md" >/dev/null
python3 "$render" managed-block --root "$root" --out "$r/A2.md" >/dev/null
expect_contains "managed block appends to an existing file" "$(cat "$r/A2.md")" "keep this"
expect_eq "managed block is replaced, not duplicated" 1 "$(grep -c 'ai-coding-config:begin' "$r/A2.md")"
echo 'hand written' > "$r/style-mine.md"
out=$(python3 "$render" output-style --root "$root" --out "$r/style-mine.md")
expect_contains "a file without the marker is skipped" "$out" "skipped"
expect_eq "a file without the marker is left alone" "hand written" "$(cat "$r/style-mine.md")"
out=$(python3 "$render" output-style --root "$root" --out "$r/style.md")
expect_contains "a generated file is reported unchanged on rerun" "$out" "unchanged $r/style.md"
m=$(printf 'symlink\t/a\ngenerated\t/b\n' | python3 "$render" manifest --out "$r/m.json" --root "$root" --scope project --target "$r" --mode symlink >/dev/null; cat "$r/m.json")
expect_json "manifest is JSON" "$m"
expect_eq "manifest lists files" 2 "$(printf '%s' "$m" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)["files"]))')"

# ---------------------------------------------------------------------------
section "install/install.sh"
install="$root/install/install.sh"
p="$work/install-both"; mkdir -p "$p"; (cd "$p" && git init -q .)
out=$("$install" --project "$p" < /dev/null 2>&1); rc=$?
expect_eq "install exits 0" 0 "$rc"
m=$(cat "$p/.claude/acc-manifest.json")
expect_eq "manifest records the scope" project "$(json_field "$m" scope)"
expect_file "skills are linked" "$p/.claude/skills/commit"
expect_eq "skill link points at the config" "$root/skills/commit" "$(readlink "$p/.claude/skills/commit")"
expect_file "rules are installed" "$p/.claude/rules/00-core-engineering.md"
if [ -f "$p/.claude/rules/10-naming-and-style.md" ] && [ ! -L "$p/.claude/rules/10-naming-and-style.md" ]; then ok "project rules are copies, not links"; else bad "project rules are copies" "expected a regular file"; fi
expect_eq "a project rule copy matches its source" "" "$(diff "$root/rules/10-naming-and-style.md" "$p/.claude/rules/10-naming-and-style.md")"
expect_file "agents are linked" "$p/.claude/agents/code-reviewer.md"
expect_file "output style is written" "$p/.claude/output-styles/plain-technical-english.md"
expect_file "settings.json is written" "$p/.claude/settings.json"
expect_eq "settings hooks point at the config" "$root/hooks/verify-gate.sh" "$(json_field "$(cat "$p/.claude/settings.json")" hooks Stop 0 hooks 0 command)"
expect_contains "CLAUDE.md carries the managed block" "$(cat "$p/CLAUDE.md")" "ai-coding-config:begin"
expect_eq "CLAUDE.md block imports AGENTS.md" "@AGENTS.md" "$(sed -n '/ai-coding-config:begin/,/ai-coding-config:end/p' "$p/CLAUDE.md" | grep '^@')"
expect_contains "AGENTS.md carries the config instructions" "$(cat "$p/AGENTS.md")" "Non-negotiables"
expect_contains "AGENTS.md block is managed" "$(cat "$p/AGENTS.md")" "ai-coding-config:begin"
expect_no_file "install writes nothing under .github" "$p/.github"
expect_file "pre-commit hook" "$p/.git/hooks/pre-commit"
expect_file "pre-push hook" "$p/.git/hooks/pre-push"
expect_eq "git config gate" "$root/hooks/verify-gate.sh" "$(cd "$p" && git config --get ai-coding-config.gate)"
expect_eq "manifest counts symlinks" 33 "$(printf '%s' "$m" | python3 -c 'import json,sys; print(sum(1 for f in json.load(sys.stdin)["files"] if f["kind"]=="symlink"))')"
expect_eq "manifest counts rule copies" 8 "$(printf '%s' "$m" | python3 -c 'import json,sys; print(sum(1 for f in json.load(sys.stdin)["files"] if f["kind"]=="copy"))')"
out=$("$install" --project "$p" < /dev/null 2>&1)
expect_not_contains "second install skips nothing" "$out" "skipped"
expect_contains "second install reports already-linked files" "$out" "already"
expect_no_file "second install makes no backup of our own settings" "$p/.claude/settings.json.acc-backup"
echo '# stale' >> "$p/.claude/rules/40-testing.md"
expect_contains "doctor reports a stale rule copy" "$("$root/install/doctor.sh" --project "$p" 2>&1)" "drift    $p/.claude/rules/40-testing.md"
out=$("$install" --project "$p" < /dev/null 2>&1)
expect_contains "rerun refreshes a rule copy it owns" "$out" "updated   $p/.claude/rules/40-testing.md"
expect_eq "refreshed copy matches its source" "" "$(diff "$root/rules/40-testing.md" "$p/.claude/rules/40-testing.md")"

p="$work/install-dry"; mkdir -p "$p"; (cd "$p" && git init -q .)
out=$("$install" --project "$p" --dry-run 2>&1)
expect_contains "--dry-run reports" "$out" "would symlink"
expect_no_file "--dry-run writes no .claude" "$p/.claude"
expect_no_file "--dry-run writes no CLAUDE.md" "$p/CLAUDE.md"
expect_empty "--dry-run sets no git config" "$(cd "$p" && git config --get ai-coding-config.gate)"

p="$work/install-copy"; mkdir -p "$p"
"$install" --project "$p" --copy >/dev/null 2>&1
if [ -d "$p/.claude/skills/commit" ] && [ ! -L "$p/.claude/skills/commit" ]; then ok "--copy copies instead of linking"; else bad "--copy" "expected a real directory"; fi
expect_file "--copy copies the skill body" "$p/.claude/skills/commit/SKILL.md"
expect_eq "--copy recorded" copy "$(json_field "$(cat "$p/.claude/acc-manifest.json")" mode)"

p="$work/install-existing"; mkdir -p "$p/.claude/rules" "$p/.claude/output-styles"; (cd "$p" && git init -q .)
echo 'mine' > "$p/.claude/rules/00-core-engineering.md"
echo 'hand written' > "$p/.claude/output-styles/plain-technical-english.md"
echo '{"permissions":{"allow":["Bash(ls:*)"]}}' > "$p/.claude/settings.json"
printf '# P\n\nexisting text\n' > "$p/AGENTS.md"
echo 'my claude' > "$p/CLAUDE.md"
printf '#!/bin/sh\nexit 0\n' > "$p/.git/hooks/pre-commit"; chmod +x "$p/.git/hooks/pre-commit"
out=$("$install" --project "$p" 2>&1)
expect_eq "existing rule file is not overwritten" mine "$(cat "$p/.claude/rules/00-core-engineering.md")"
expect_eq "existing hand-written output style is not overwritten" "hand written" "$(cat "$p/.claude/output-styles/plain-technical-english.md")"
expect_eq "existing pre-commit hook is not overwritten" "#!/bin/sh
exit 0" "$(cat "$p/.git/hooks/pre-commit")"
expect_file "pre-push is still installed" "$p/.git/hooks/pre-push"
expect_eq "existing AGENTS.md text is kept at the top" "# P" "$(head -1 "$p/AGENTS.md")"
expect_contains "existing AGENTS.md text is kept" "$(cat "$p/AGENTS.md")" "existing text"
expect_contains "managed block is appended to AGENTS.md" "$(cat "$p/AGENTS.md")" "ai-coding-config:begin"
expect_eq "existing CLAUDE.md text is kept at the top" "my claude" "$(head -1 "$p/CLAUDE.md")"
expect_contains "managed block is appended to CLAUDE.md" "$(cat "$p/CLAUDE.md")" "ai-coding-config:begin"
expect_eq "settings backup holds the original" '{"permissions":{"allow":["Bash(ls:*)"]}}' "$(cat "$p/.claude/settings.json.acc-backup")"
s=$(cat "$p/.claude/settings.json")
expect_eq "settings merge keeps permissions" '["Bash(ls:*)"]' "$(json_field "$s" permissions allow)"
expect_contains "settings merge adds our hooks" "$s" "ai-coding-config:"
"$install" --project "$p" >/dev/null 2>&1
expect_eq "rerun keeps the first backup" '{"permissions":{"allow":["Bash(ls:*)"]}}' "$(cat "$p/.claude/settings.json.acc-backup")"

out=$("$install" --user --dry-run 2>&1); rc=$?
expect_eq "--user --dry-run exits 0" 0 "$rc"
expect_contains "--user targets ~/.claude" "$out" "$HOME/.claude"
expect_no_file "--user --dry-run writes nothing" "$HOME/.claude"
"$install" --user >/dev/null 2>&1
expect_file "--user links skills into ~/.claude" "$HOME/.claude/skills/commit"
expect_eq "--user CLAUDE.md imports AGENTS.md" "@AGENTS.md" "$(grep '^@' "$HOME/.claude/CLAUDE.md")"
expect_eq "--user links AGENTS.md into ~/.claude" "$root/AGENTS.md" "$(readlink "$HOME/.claude/AGENTS.md")"
expect_eq "--user rules stay links" "$root/rules/00-core-engineering.md" "$(readlink "$HOME/.claude/rules/00-core-engineering.md")"
expect_eq "--user settings carry the hooks" "$root/hooks/verify-gate.sh" "$(json_field "$(cat "$HOME/.claude/settings.json")" hooks Stop 0 hooks 0 command)"

expect_eq "no scope is an error" 2 "$("$install" >/dev/null 2>&1; echo $?)"
expect_eq "unknown option is an error" 2 "$("$install" --user --bogus >/dev/null 2>&1; echo $?)"

# ---------------------------------------------------------------------------
section "install/doctor.sh and install/uninstall.sh"
doctor="$root/install/doctor.sh"; uninstall="$root/install/uninstall.sh"
p="$work/roundtrip"; mkdir -p "$p"; (cd "$p" && git init -q . && echo '{"test":"true"}' > .agentconfig.json && git add . && git -c user.email=t@t -c user.name=t commit -qm init)
expect_eq "doctor without an install exits 1" 1 "$("$doctor" --project "$p" >/dev/null 2>&1; echo $?)"
"$install" --project "$p" >/dev/null 2>&1
"$install" --project "$p" >/dev/null 2>&1
m=$(cat "$p/.claude/acc-manifest.json")
expect_eq "manifest keeps first-run entries after a rerun" 1 "$(printf '%s' "$m" | python3 -c 'import json,sys; print(sum(1 for f in json.load(sys.stdin)["files"] if f["path"].endswith("/CLAUDE.md")))')"
out=$("$doctor" --project "$p" 2>&1); rc=$?
expect_eq "doctor on a healthy install exits 0" 0 "$rc"
expect_contains "doctor reports no problems" "$out" "No problems."
expect_contains "doctor lists the gate commands" "$out" "test       true"
echo '# extra' >> "$p/.claude/output-styles/plain-technical-english.md"
out=$("$doctor" --project "$p" 2>&1); rc=$?
expect_eq "doctor exits 1 on drift" 1 "$rc"
expect_contains "doctor names the drifted file" "$out" "drift    $p/.claude/output-styles/plain-technical-english.md"
"$install" --project "$p" >/dev/null 2>&1
expect_eq "install regenerates the drifted file" 0 "$("$doctor" --project "$p" >/dev/null 2>&1; echo $?)"
rm "$p/.claude/skills/commit"
expect_contains "doctor reports a missing link" "$("$doctor" --project "$p" 2>&1)" "missing link $p/.claude/skills/commit"
"$install" --project "$p" >/dev/null 2>&1
(cd "$p" && git config --unset ai-coding-config.gate)
expect_contains "doctor reports an unset gate config" "$("$doctor" --project "$p" 2>&1)" "ai-coding-config.gate is unset"
(cd "$p" && git config ai-coding-config.gate "$gate")
rm "$p/.agentconfig.json"
expect_contains "doctor reports when no commands are detected" "$("$doctor" --project "$p" 2>&1)" "no verification commands detected"
echo '{"test":"true"}' > "$p/.agentconfig.json"
out=$("$uninstall" --project "$p" --dry-run 2>&1)
expect_contains "uninstall dry run reports" "$out" "would remove"
expect_file "uninstall dry run removes nothing" "$p/.claude/acc-manifest.json"
"$uninstall" --project "$p" >/dev/null 2>&1
expect_empty "uninstall leaves the tree as git knew it" "$(cd "$p" && git status --short)"
expect_no_file "uninstall removes .claude" "$p/.claude"
expect_no_file "uninstall removes the CLAUDE.md it created" "$p/CLAUDE.md"
expect_no_file "uninstall removes the AGENTS.md it created" "$p/AGENTS.md"
expect_no_file "uninstall removes the pre-commit hook" "$p/.git/hooks/pre-commit"
expect_empty "uninstall unsets the gate config" "$(cd "$p" && git config --get ai-coding-config.gate)"
expect_eq "uninstall twice is a no-op" 0 "$("$uninstall" --project "$p" >/dev/null 2>&1; echo $?)"

p="$work/roundtrip-existing"; mkdir -p "$p/.claude"; (cd "$p" && git init -q .)
printf '{"permissions": {"allow": ["Bash(ls:*)"]}}\n' > "$p/.claude/settings.json"
printf '# Mine\n\nkeep this\n' > "$p/CLAUDE.md"; echo 'team agents' > "$p/AGENTS.md"
printf '#!/bin/sh\nexit 0\n' > "$p/.git/hooks/pre-push"; chmod +x "$p/.git/hooks/pre-push"
"$install" --project "$p" >/dev/null 2>&1
"$uninstall" --project "$p" >/dev/null 2>&1
expect_eq "uninstall restores the settings backup byte for byte" '{"permissions": {"allow": ["Bash(ls:*)"]}}' "$(cat "$p/.claude/settings.json")"
expect_no_file "uninstall removes the backup it restored" "$p/.claude/settings.json.acc-backup"
expect_eq "uninstall strips the managed block from CLAUDE.md and keeps the rest" "# Mine

keep this" "$(cat "$p/CLAUDE.md")"
expect_eq "uninstall leaves AGENTS.md alone" "team agents" "$(cat "$p/AGENTS.md")"
expect_eq "uninstall keeps a pre-push hook it did not write" "#!/bin/sh
exit 0" "$(cat "$p/.git/hooks/pre-push")"
expect_no_file "uninstall removes the pre-commit hook it wrote" "$p/.git/hooks/pre-commit"

p="$work/roundtrip-edited"; mkdir -p "$p/.claude"
printf '{"a": 1}\n' > "$p/.claude/settings.json"
"$install" --project "$p" --no-git-hooks >/dev/null 2>&1
python3 -c "import json; p='$p/.claude/settings.json'; d=json.load(open(p)); d['b']=2; json.dump(d,open(p,'w'))"
"$uninstall" --project "$p" >/dev/null 2>&1
expect_eq "uninstall keeps settings edited after install" '{"a": 1, "b": 2}' "$(python3 -c "import json; print(json.dumps(json.load(open('$p/.claude/settings.json'))))")"
expect_file "uninstall keeps the backup when settings diverged" "$p/.claude/settings.json.acc-backup"

rm -rf "$HOME/.claude"
"$install" --user >/dev/null 2>&1
expect_eq "doctor --user on a healthy install" 0 "$("$doctor" --user >/dev/null 2>&1; echo $?)"
"$uninstall" --user >/dev/null 2>&1
expect_no_file "uninstall --user removes ~/.claude when empty" "$HOME/.claude"

# ---------------------------------------------------------------------------
printf '\n%d passed, %d failed\n' "$pass" "$fail"
if [ "$fail" != 0 ]; then
  printf 'failed:%s\n' "$failed_names"
  exit 1
fi
exit 0
