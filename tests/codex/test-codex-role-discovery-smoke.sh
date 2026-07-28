#!/usr/bin/env bash
# Deterministic contract tests for the isolated Codex role discovery smoke
# harness. These tests never invoke a real Codex model: they verify the
# harness's skip contract, its input isolation, its temporary-home layout,
# and its fail-closed behavior against a fake Codex executable.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SMOKE="$SCRIPT_DIR/run-codex-role-discovery-smoke.sh"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

write_fake_codex() {
  # $1: path, $2: "fail-explorer" or "success"
  local path="$1" mode="$2"
  {
    printf '%s\n' '#!/usr/bin/env bash'
    printf '%s\n' 'set -euo pipefail'
    printf '%s\n' 'last=""'
    printf '%s\n' 'prompt=""'
    printf '%s\n' 'while [[ $# -gt 0 ]]; do'
    printf '%s\n' '  case "$1" in'
    printf '%s\n' '    --output-last-message) last="$2"; shift 2 ;;'
    printf '%s\n' '    -*) shift; if [[ "${1:-}" != -* && -n "${1:-}" ]]; then shift; fi ;;'
    printf '%s\n' '    *) prompt="$1"; shift ;;'
    printf '%s\n' '  esac'
    printf '%s\n' 'done'
    if [[ "$mode" == "success" ]]; then
      printf '%s\n' '[[ -n "${CODEX_HOME:-}" ]] || { echo "CODEX_HOME missing" >&2; exit 3; }'
      printf '%s\n' '[[ -L "$CODEX_HOME/agents/superpowers" ]] || { echo "agents link missing" >&2; exit 3; }'
      printf '%s\n' '[[ -f "$CODEX_HOME/auth.json" ]] || { echo "auth.json missing" >&2; exit 3; }'
      printf '%s\n' 'perms="$(stat -c %a "$CODEX_HOME/auth.json")"'
      printf '%s\n' '[[ "$perms" == "600" ]] || { echo "auth.json perms $perms" >&2; exit 3; }'
      printf '%s\n' '[[ "$prompt" == *"fork_turns set to none"* ]] || { echo "fork_turns instruction missing" >&2; exit 3; }'
    fi
    printf '%s\n' 'printf '"'"'{"type":"item.completed","item":{"type":"collab_tool_call","tool":"spawn_agent"}}\n'"'"
    if [[ "$mode" == "fail-explorer" ]]; then
      printf '%s\n' 'if [[ "$prompt" == *superpowers-explorer* ]]; then'
      printf '%s\n' '  printf "SPAWN FAILED\n" >"$last"'
      printf '%s\n' 'else'
      printf '%s\n' '  printf "superpowers-role\nDONE\n" >"$last"'
      printf '%s\n' 'fi'
    else
      printf '%s\n' 'printf "superpowers-role\nDONE\n" >"$last"'
    fi
  } >"$path"
  chmod +x "$path"
}

# 1. Opt-in contract: without a source home the harness skips with exit 2.
set +e
OUTPUT="$(env -u SUPERPOWERS_SMOKE_SOURCE_CODEX_HOME \
  -u SUPERPOWERS_SMOKE_ALLOW_DEFAULT_SOURCE bash "$SMOKE" 2>&1)"
STATUS=$?
set -e
[[ "$STATUS" -eq 2 && "$OUTPUT" == *"SMOKE SKIP"* ]] ||
  fail "missing source home must skip with exit 2 (got $STATUS: $OUTPUT)"

# 2. A source home without auth.json skips with exit 2.
SOURCE_HOME="$TEST_ROOT/source-empty"
mkdir -p "$SOURCE_HOME"
set +e
OUTPUT="$(SUPERPOWERS_SMOKE_SOURCE_CODEX_HOME="$SOURCE_HOME" bash "$SMOKE" 2>&1)"
STATUS=$?
set -e
[[ "$STATUS" -eq 2 && "$OUTPUT" == *"auth.json"* ]] ||
  fail "source home without auth.json must skip with exit 2 (got $STATUS: $OUTPUT)"

# 3. Fail-closed on spawn failure: the fake Codex parent reports
# SPAWN FAILED for superpowers-explorer; the harness must exit 1.
FAKE_HOME="$TEST_ROOT/source-auth"
mkdir -p "$FAKE_HOME"
printf '{"tokens":{}}\n' >"$FAKE_HOME/auth.json"
chmod 600 "$FAKE_HOME/auth.json"
FAKE_BIN="$TEST_ROOT/fake-bin"
mkdir -p "$FAKE_BIN"
write_fake_codex "$FAKE_BIN/codex" fail-explorer

set +e
OUTPUT="$(SUPERPOWERS_CODEX_BIN="$FAKE_BIN/codex" \
  SUPERPOWERS_SMOKE_SOURCE_CODEX_HOME="$FAKE_HOME" \
  bash "$SMOKE" 2>&1)"
STATUS=$?
set -e
[[ "$STATUS" -eq 1 && "$OUTPUT" == *"could not spawn: superpowers-explorer"* ]] ||
  fail "spawn failure must fail closed with exit 1 (got $STATUS: $OUTPUT)"

# 4. All-success fake run: the harness must exit 0 and print its pass line,
# proving the wiring (temporary home, agents link, nine sessions) works.
write_fake_codex "$FAKE_BIN/codex" success

set +e
OUTPUT="$(SUPERPOWERS_CODEX_BIN="$FAKE_BIN/codex" \
  SUPERPOWERS_SMOKE_SOURCE_CODEX_HOME="$FAKE_HOME" \
  bash "$SMOKE" 2>&1)"
STATUS=$?
set -e
[[ "$STATUS" -eq 0 && "$OUTPUT" == *"smoke passed: 9 roles"* ]] ||
  fail "all-success fake run must pass (got $STATUS: $OUTPUT)"
[[ "$(printf '%s' "$OUTPUT" | grep -c 'spawned and returned')" -eq 9 ]] ||
  fail "expected nine spawn confirmations: $OUTPUT"

printf 'All Codex role discovery smoke contract tests passed\n'
