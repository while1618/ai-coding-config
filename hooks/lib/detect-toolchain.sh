#!/usr/bin/env bash
# Detects a repository's verification commands and prints them as TSV:
#
#   <category>\t<command>\t<takes-file-args 0|1>
#
# Categories: format, lint, typecheck, test, note. A note line carries a message for a
# person, not a command. takes-file-args is 1 when the gate may append file paths.
#
# Usage: detect-toolchain.sh [<repo-dir>]
#
# .agentconfig.json is read first. A key set there (test, lint, typecheck, format) replaces
# detection for that category, and "" means the project has no such command. "skip": true
# turns the whole gate off. "gate" names the categories the Stop hook enforces.
# After that, package.json, pyproject.toml, go.mod, Cargo.toml, pom.xml, gradle, and the
# Makefile each add what they declare.

here=$(cd "$(dirname "$0")" && pwd -P)
. "$here/json.sh"

dir=${1:-.}
cd "$dir" 2>/dev/null || exit 0

commands=0
emit() { printf '%s\t%s\t%s\n' "$1" "$2" "$3"; [ "$1" != note ] && commands=$((commands + 1)); return 0; }
note() { emit note "$1" 0; }

# Categories pinned by .agentconfig.json, as a space-separated list.
pinned=''
is_pinned() { case " $pinned " in *" $1 "*) return 0 ;; esac; return 1; }
add() { is_pinned "$1" || emit "$1" "$2" "$3"; }

if [ -f .agentconfig.json ]; then
  config=$(cat .agentconfig.json)
  if [ "$(json_get "$config" skip)" = true ]; then
    note "skip: .agentconfig.json turns the gate off"
    exit 0
  fi
  for category in format lint typecheck test; do
    # A key that is present but "" pins the category to "none".
    present=$(printf '%s' "$config" | grep -c "\"$category\"[[:space:]]*:")
    value=$(json_get "$config" "$category")
    if [ -n "$value" ]; then
      emit "$category" "$value" 0
      pinned="$pinned $category"
    elif [ "$present" != 0 ]; then
      pinned="$pinned $category"
    fi
  done
  gate=$(json_get "$config" gate)
  [ -n "$gate" ] && note "gate: $(printf '%s' "$gate" | tr -d '[]" ')"
  note ".agentconfig.json read"
fi


if [ -f package.json ]; then
  pkg=$(cat package.json)
  run='npm run'
  if [ -f pnpm-lock.yaml ]; then run='pnpm run'
  elif [ -f yarn.lock ]; then run='yarn run'
  elif [ -f bun.lockb ] || [ -f bun.lock ]; then run='bun run'
  fi
  script() { json_get "$pkg" scripts "$1"; }
  test_script=$(script test)
  case "$test_script" in
    ''|*'no test specified'*) ;;
    *) add test "$run test" 0 ;;
  esac
  [ -n "$(script lint)" ] && add lint "$run lint" 0
  if [ -n "$(script typecheck)" ]; then add typecheck "$run typecheck" 0
  elif [ -n "$(script type-check)" ]; then add typecheck "$run type-check" 0
  elif [ -f tsconfig.json ] && [ -n "$(json_get "$pkg" devDependencies typescript)$(json_get "$pkg" dependencies typescript)" ]; then
    add typecheck 'npx tsc --noEmit' 0
  fi
  if [ -n "$(script format:check)" ]; then add format "$run format:check" 0
  elif [ -n "$(script prettier:check)" ]; then add format "$run prettier:check" 0
  elif [ -n "$(json_get "$pkg" devDependencies prettier)" ]; then add format 'npx prettier --check' 1
  fi
fi

if [ -f pyproject.toml ]; then
  py=$(cat pyproject.toml)
  prefix=''
  if [ -f uv.lock ]; then prefix='uv run '
  elif [ -f poetry.lock ]; then prefix='poetry run '
  fi
  has() { printf '%s' "$py" | grep -q "$1"; }
  if has 'tool.ruff' || has '"ruff' || has "'ruff"; then
    add lint "${prefix}ruff check" 1
    add format "${prefix}ruff format --check" 1
  elif has 'tool.black' || has '"black' || has "'black"; then
    add format "${prefix}black --check" 1
  fi
  if has 'tool.mypy' || has '"mypy' || has "'mypy"; then add typecheck "${prefix}mypy ." 0
  elif has 'tool.pyright' || has '"pyright' || has "'pyright"; then add typecheck "${prefix}pyright" 0
  fi
  if has 'pytest' || [ -d tests ] || [ -d test ]; then add test "${prefix}pytest" 0; fi
elif [ -f setup.py ] || [ -f setup.cfg ] || [ -f pytest.ini ]; then
  add test pytest 0
fi

if [ -f go.mod ]; then
  add format 'sh -c '"'"'test -z "$(gofmt -l "$@")"'"'"' gofmt' 1
  add lint 'go vet ./...' 0
  add test 'go test ./...' 0
fi

if [ -f Cargo.toml ]; then
  add format 'cargo fmt --check' 0
  if command -v cargo-clippy >/dev/null 2>&1; then add lint 'cargo clippy --all-targets -- -D warnings' 0; fi
  add typecheck 'cargo check' 0
  add test 'cargo test' 0
fi

if [ -f pom.xml ]; then
  if [ -x ./mvnw ]; then add test './mvnw -q -B test' 0; else add test 'mvn -q -B test' 0; fi
fi

if [ -f build.gradle ] || [ -f build.gradle.kts ]; then
  if [ -x ./gradlew ]; then add test './gradlew test' 0; else add test 'gradle test' 0; fi
fi

if [ -f Makefile ] || [ -f makefile ] || [ -f GNUmakefile ]; then
  mk=$(cat Makefile makefile GNUmakefile 2>/dev/null)
  target() { printf '%s\n' "$mk" | grep -q "^$1[[:space:]]*:"; }
  if target format; then add format 'make format' 0
  elif target fmt; then add format 'make fmt' 0
  fi
  target lint && add lint 'make lint' 0
  target typecheck && add typecheck 'make typecheck' 0
  if target test; then add test 'make test' 0
  elif target check; then add test 'make check' 0
  fi
fi

if [ "$commands" = 0 ]; then
  note "no verification commands found: add .agentconfig.json to name them"
fi
exit 0
