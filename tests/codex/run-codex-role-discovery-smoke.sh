#!/usr/bin/env bash
# Isolated Codex-home smoke harness for native Superpowers role discovery
# and read-only spawns.
#
# Contract:
#   - Non-destructive: never installs or removes a plugin or marketplace and
#     never edits this repository. It creates a private temporary CODEX_HOME,
#     copies only the auth/config/catalog inputs listed below from a
#     controller-supplied source Codex home, symlinks this checkout's agents
#     directory into the temporary home, and removes the temporary home on
#     exit.
#   - Opt-in: requires SUPERPOWERS_SMOKE_SOURCE_CODEX_HOME naming a readable
#     source Codex home (the default ~/.codex is used only when explicitly
#     confirmed with SUPERPOWERS_SMOKE_ALLOW_DEFAULT_SOURCE=1).
#   - Exit 0: every requested role spawned in a completely fresh session and
#     returned a child result.
#   - Exit 1: a genuine failure (role warning, spawn failure, missing child
#     result, unexpected repository modification).
#   - Exit 2: prerequisites unavailable (real credentials/network not
#     usable); the harness did not run and nothing was verified.
#
# Discovery proof: a completely fresh session is started per requested role
# with this checkout's agents directory linked into the temporary home. A
# malformed, duplicate, or missing role definition makes the session fail
# or the parent report SPAWN FAILED, so nine successful named spawns prove
# all nine definitions loaded without role warnings.
#
# Observability boundary (Codex 0.145.0): public --json output emits
# item.completed and collab_tool_call records proving the parent invoked
# the collaboration tool, but those records do not carry the selected role
# name or the child's effective model or reasoning effort, and the
# temporary home's state database persists only the parent session row.
# This harness therefore asserts actual role spawn through the
# parent-reported child result plus emitted collaboration records, and it
# relies on scripts/validate-codex-ai-roles.py plus `codex debug models`
# for the model and effort enforcement side. It does not invent a metadata
# assertion that Codex 0.145.0 does not expose.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CODEX_BIN="${SUPERPOWERS_CODEX_BIN:-codex}"
CALL_TIMEOUT_SECONDS="${SUPERPOWERS_SMOKE_TIMEOUT_SECONDS:-600}"

SMOKE_SKIP() {
  printf 'SMOKE SKIP: %s\n' "$*" >&2
  exit 2
}

SMOKE_FAIL() {
  printf 'SMOKE FAIL: %s\n' "$*" >&2
  exit 1
}

SOURCE_HOME="${SUPERPOWERS_SMOKE_SOURCE_CODEX_HOME:-}"
if [[ -z "$SOURCE_HOME" ]]; then
  if [[ "${SUPERPOWERS_SMOKE_ALLOW_DEFAULT_SOURCE:-}" == "1" ]]; then
    SOURCE_HOME="${CODEX_HOME:-$HOME/.codex}"
  else
    SMOKE_SKIP "SUPERPOWERS_SMOKE_SOURCE_CODEX_HOME is not set"
  fi
fi
[[ -d "$SOURCE_HOME" ]] || SMOKE_SKIP "source Codex home not found: $SOURCE_HOME"
[[ -f "$SOURCE_HOME/auth.json" ]] ||
  SMOKE_SKIP "source Codex home has no auth.json: $SOURCE_HOME"
command -v "$CODEX_BIN" >/dev/null 2>&1 ||
  SMOKE_SKIP "Codex executable not found: $CODEX_BIN"
command -v python3 >/dev/null 2>&1 || SMOKE_SKIP "python3 is required"
[[ "$CALL_TIMEOUT_SECONDS" =~ ^[1-9][0-9]*$ ]] ||
  SMOKE_FAIL "SUPERPOWERS_SMOKE_TIMEOUT_SECONDS must be a positive integer"

WORK_DIR="$(mktemp -d)"
TEMP_HOME="$WORK_DIR/codex-home"
mkdir -p "$TEMP_HOME/agents"
chmod 700 "$WORK_DIR" "$TEMP_HOME"
cleanup() {
  chmod -R u+rwX "$WORK_DIR" 2>/dev/null || true
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# Copy only the minimum auth/config/catalog inputs, preserving restrictive
# permissions. Nothing else from the source home enters the temporary home.
copy_input() {
  local name="$1" required="$2"
  if [[ -f "$SOURCE_HOME/$name" ]]; then
    cp -p "$SOURCE_HOME/$name" "$TEMP_HOME/$name"
    chmod 600 "$TEMP_HOME/$name"
  elif [[ "$required" == "required" ]]; then
    SMOKE_SKIP "required input missing from source home: $name"
  fi
}
copy_input auth.json required
copy_input config.toml optional
copy_input models.json optional
copy_input models_cache.json optional

# Expose this checkout's native roles through the managed-link shape the
# installer creates. This link lives only inside the temporary home.
ln -s "$REPO_ROOT/agents" "$TEMP_HOME/agents/superpowers"

EXPECTED_ROLES=(
  superpowers-explorer
  superpowers-implementer
  superpowers-recovery
  superpowers-investigator
  superpowers-implementer-mechanical
  superpowers-implementer-complex
  superpowers-task-reviewer
  superpowers-re-reviewer
  superpowers-final-reviewer
)

repo_status_before="$(git -C "$REPO_ROOT" status --porcelain)"

spawn_role() {
  local role="$1" label="$2"
  local prompt_file="$WORK_DIR/prompt-$label.txt"
  local jsonl="$WORK_DIR/$label.jsonl"
  local last="$WORK_DIR/$label-last.txt"
  local log="$WORK_DIR/$label.log"
  {
    printf 'You are the parent. Do not perform the child task yourself. '
    printf 'Spawn exactly one subagent using agent_type %s with fork_turns set to none. ' "$role"
    printf 'Ask it only to reply with exactly DONE without reading or modifying files. '
    printf 'Wait for it. If the spawn or role is unavailable, answer exactly SPAWN FAILED; otherwise answer exactly DONE.\n'
  } >"$prompt_file"
  printf 'Smoke session %s (role %s)...\n' "$label" "$role"
  if ! env CODEX_HOME="$TEMP_HOME" timeout "$CALL_TIMEOUT_SECONDS" \
    "$CODEX_BIN" -a never exec --ephemeral --ignore-rules \
    --skip-git-repo-check --sandbox read-only -C /tmp \
    -m gpt-5.6-luna -c 'model_reasoning_effort="medium"' \
    --json --output-last-message "$last" \
    "$(cat "$prompt_file")" >"$jsonl" 2>"$log"; then
    cat "$log" >&2
    SMOKE_FAIL "session $label exited nonzero"
  fi
  # A fresh session that rejects a role definition fails closed here.
  if grep -Eiq 'malformed (agent|role)|invalid (agent|role)|duplicate (agent|role)|unknown role|failed to load (agent|role)|Full-history forked agents inherit' "$log" "$jsonl"; then
    cat "$log" >&2
    SMOKE_FAIL "session $label reported a malformed/duplicate/missing role warning"
  fi
  if grep -q 'SPAWN FAILED' "$last"; then
    cat "$last" >&2
    SMOKE_FAIL "requested role could not spawn: $role"
  fi
  if ! grep -q 'DONE' "$last"; then
    cat "$last" >&2
    SMOKE_FAIL "child for role $role did not return its result"
  fi
  if ! grep -Eq 'collab_tool_call|spawn_agent' "$jsonl"; then
    cat "$jsonl" >&2
    cat "$log" >&2
    SMOKE_FAIL "session $label emitted no collaboration tool-call record"
  fi
  printf 'Smoke: %s spawned and returned a child result.\n' "$role"
}

label_index=0
for role in "${EXPECTED_ROLES[@]}"; do
  label_index=$((label_index + 1))
  spawn_role "$role" "spawn-$label_index"
done

repo_status_after="$(git -C "$REPO_ROOT" status --porcelain)"
[[ "$repo_status_before" == "$repo_status_after" ]] ||
  SMOKE_FAIL "repository working tree changed during the smoke run"

printf 'Codex role discovery smoke passed: 9 roles discovered and spawned in fresh isolated sessions.\n'
