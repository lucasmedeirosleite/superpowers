#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INSTALLER="$REPO_ROOT/scripts/install-codex-variant.sh"
UNINSTALLER="$REPO_ROOT/scripts/uninstall-codex-variant.sh"
FAKE_CODEX="$SCRIPT_DIR/fixtures/fake-codex.sh"
TEST_ROOT="$(mktemp -d)"
CASE_NUMBER=0
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

fresh_case() {
  CASE_NUMBER=$((CASE_NUMBER + 1))
  CASE_ROOT="$TEST_ROOT/case-$CASE_NUMBER"
  FAKE_STATE="$CASE_ROOT/fake"
  TEST_CODEX_HOME="$CASE_ROOT/codex-home"
  mkdir -p "$FAKE_STATE" "$TEST_CODEX_HOME"
  printf 'codex-cli 0.145.0\n' >"$FAKE_STATE/version"
  printf '{"marketplaces":[]}\n' >"$FAKE_STATE/marketplaces.json"
  printf '{"installed":[]}\n' >"$FAKE_STATE/plugins.json"
  : >"$FAKE_STATE/commands.log"
  python3 - "$FAKE_STATE/models.json" <<'PY'
import json, sys
models = [
    ("gpt-5.6-sol", ["low", "medium", "high"]),
    ("gpt-5.6-terra", ["low", "medium", "high"]),
    ("gpt-5.6-luna", ["low", "medium", "high"]),
    ("kimi-oauth/k3", ["low", "high", "max"]),
]
json.dump({"models": [
    {"slug": slug, "supported_reasoning_levels": [{"effort": effort} for effort in efforts]}
    for slug, efforts in models
]}, open(sys.argv[1], "w", encoding="utf-8"))
PY
}

run_capture() {
  set +e
  OUTPUT="$(
    SUPERPOWERS_CODEX_BIN="$FAKE_CODEX" \
    SUPERPOWERS_CODEX_HOME="$TEST_CODEX_HOME" \
    SUPERPOWERS_FAKE_CODEX_STATE="$FAKE_STATE" \
    "$@" 2>&1
  )"
  STATUS=$?
  set -e
}

seed_plugin() {
  python3 - "$FAKE_STATE/plugins.json" "$1" <<'PY'
import json, sys
json.dump({"installed": [{
    "pluginId": sys.argv[2],
    "name": "superpowers",
    "installed": True,
}]}, open(sys.argv[1], "w", encoding="utf-8"))
PY
}

seed_marketplace() {
  python3 - "$FAKE_STATE/marketplaces.json" "$1" <<'PY'
import json, sys
json.dump({"marketplaces": [{
    "name": "superpowers-dev",
    "root": sys.argv[2],
    "marketplaceSource": {"sourceType": "local", "source": sys.argv[2]},
}]}, open(sys.argv[1], "w", encoding="utf-8"))
PY
}

remove_model_or_effort() {
  python3 - "$FAKE_STATE/models.json" "$1" "$2" <<'PY'
import json, sys
path, slug, effort = sys.argv[1:]
data = json.load(open(path, encoding="utf-8"))
if effort == "-":
    data["models"] = [model for model in data["models"] if model["slug"] != slug]
else:
    model = next(model for model in data["models"] if model["slug"] == slug)
    model["supported_reasoning_levels"] = [
        item for item in model["supported_reasoning_levels"]
        if item["effort"] != effort
    ]
json.dump(data, open(path, "w", encoding="utf-8"))
PY
}

fresh_case
run_capture "$INSTALLER"
[[ "$STATUS" -eq 0 ]] || fail "fresh install: $OUTPUT"
[[ -L "$TEST_CODEX_HOME/agents/superpowers" ]] || fail "agents link missing"
[[ "$(readlink "$TEST_CODEX_HOME/agents/superpowers")" == "$REPO_ROOT/agents" ]] ||
  fail "agents link target"
python3 - "$TEST_CODEX_HOME/superpowers-variant-state.json" <<'PY'
import json, sys
state = json.load(open(sys.argv[1], encoding="utf-8"))
assert state["marketplace_added"] is True
assert state["plugin_added"] is True
assert state["agents_link_added"] is True
PY
grep -q '^plugin marketplace add ' "$FAKE_STATE/commands.log" ||
  fail "marketplace add not recorded"
grep -q '^plugin add superpowers@superpowers-dev --json$' "$FAKE_STATE/commands.log" ||
  fail "plugin add not recorded"

before="$(wc -l <"$FAKE_STATE/commands.log")"
run_capture "$INSTALLER"
after="$(wc -l <"$FAKE_STATE/commands.log")"
[[ "$STATUS" -eq 0 && "$before" -eq "$after" ]] || fail "install is not idempotent"

fresh_case
mkdir -p "$TEST_CODEX_HOME/agents/superpowers"
run_capture "$INSTALLER"
[[ "$STATUS" -ne 0 && ! -s "$FAKE_STATE/commands.log" ]] ||
  fail "foreign agents target mutated state"

fresh_case
seed_plugin "superpowers@openai-curated"
run_capture "$INSTALLER"
[[ "$STATUS" -ne 0 && "$OUTPUT" == *"explicit user approval"* &&
  ! -s "$FAKE_STATE/commands.log" ]] ||
  fail "official plugin conflict diagnostic"

fresh_case
printf '{not valid JSON\n' >"$FAKE_STATE/plugins.json"
run_capture "$INSTALLER"
[[ "$STATUS" -ne 0 && ! -s "$FAKE_STATE/commands.log" ]] ||
  fail "malformed plugin list mutated state"

fresh_case
printf '{"installed":[{"name":"superpowers","installed":true}]}\n' >"$FAKE_STATE/plugins.json"
run_capture "$INSTALLER"
[[ "$STATUS" -ne 0 && ! -s "$FAKE_STATE/commands.log" ]] ||
  fail "incomplete plugin list mutated state"

fresh_case
seed_marketplace "/different/checkout"
run_capture "$INSTALLER"
[[ "$STATUS" -ne 0 && ! -s "$FAKE_STATE/commands.log" ]] ||
  fail "foreign marketplace mutated state"

fresh_case
printf 'codex-cli 0.144.0\n' >"$FAKE_STATE/version"
run_capture "$INSTALLER"
[[ "$STATUS" -ne 0 && "$OUTPUT" == *"0.145.0 or newer"* ]] ||
  fail "unsupported version diagnostic"

fresh_case
remove_model_or_effort "kimi-oauth/k3" "-"
run_capture "$INSTALLER"
[[ "$STATUS" -ne 0 && "$OUTPUT" == *"kimi-oauth/k3 is unavailable"* ]] ||
  fail "missing model diagnostic"

fresh_case
remove_model_or_effort "kimi-oauth/k3" "max"
run_capture "$INSTALLER"
[[ "$STATUS" -ne 0 && "$OUTPUT" == *"does not support reasoning max"* ]] ||
  fail "missing effort diagnostic"

fresh_case
run_capture "$INSTALLER"
[[ "$STATUS" -eq 0 ]] || fail "owned setup for uninstall"
run_capture "$UNINSTALLER"
[[ "$STATUS" -eq 0 ]] || fail "owned uninstall: $OUTPUT"
[[ ! -e "$TEST_CODEX_HOME/agents/superpowers" ]] || fail "owned link remains"
[[ ! -e "$TEST_CODEX_HOME/superpowers-variant-state.json" ]] || fail "state remains"
grep -q '^plugin remove superpowers@superpowers-dev --json$' "$FAKE_STATE/commands.log" ||
  fail "owned plugin not removed"
grep -q '^plugin marketplace remove superpowers-dev --json$' "$FAKE_STATE/commands.log" ||
  fail "owned marketplace not removed"

fresh_case
seed_marketplace "$REPO_ROOT"
run_capture "$INSTALLER"
[[ "$STATUS" -eq 0 ]] || fail "partial-state setup"
python3 - "$TEST_CODEX_HOME/superpowers-variant-state.json" <<'PY'
import json, sys
state = json.load(open(sys.argv[1], encoding="utf-8"))
assert state["marketplace_added"] is False
assert state["plugin_added"] is True
PY
seed_marketplace "/different/checkout"
before="$(wc -l <"$FAKE_STATE/commands.log")"
run_capture "$UNINSTALLER"
after="$(wc -l <"$FAKE_STATE/commands.log")"
[[ "$STATUS" -ne 0 && "$before" -eq "$after" &&
  -L "$TEST_CODEX_HOME/agents/superpowers" ]] ||
  fail "repointed marketplace did not stop uninstall before removal"

fresh_case
run_capture "$INSTALLER"
[[ "$STATUS" -eq 0 ]] || fail "owned setup for foreign-link test"
unlink "$TEST_CODEX_HOME/agents/superpowers"
mkdir -p "$CASE_ROOT/foreign-agents"
ln -s "$CASE_ROOT/foreign-agents" "$TEST_CODEX_HOME/agents/superpowers"
before="$(wc -l <"$FAKE_STATE/commands.log")"
run_capture "$UNINSTALLER"
after="$(wc -l <"$FAKE_STATE/commands.log")"
[[ "$STATUS" -ne 0 && "$before" -eq "$after" ]] ||
  fail "foreign link did not stop uninstall before mutation"

fresh_case
run_capture "$UNINSTALLER"
[[ "$STATUS" -eq 0 && "$OUTPUT" == *"No managed"* ]] ||
  fail "missing state is not a no-op"

printf 'All Codex variant installer tests passed\n'
