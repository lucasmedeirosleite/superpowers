#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CASES="$SCRIPT_DIR/ai-role-routing-cases.json"
SCHEMA="$SCRIPT_DIR/ai-role-routing-output.schema.json"
CODEX_BIN="${SUPERPOWERS_CODEX_BIN:-codex}"
EVAL_MODEL="${SUPERPOWERS_EVAL_MODEL:-gpt-5.6-luna}"
MODE="${1:---post-change}"
REPETITIONS="${SUPERPOWERS_EVAL_REPETITIONS:-5}"
CALL_TIMEOUT_SECONDS="${SUPERPOWERS_EVAL_TIMEOUT_SECONDS:-180}"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

[[ "$REPETITIONS" =~ ^[1-9][0-9]*$ ]] ||
  { printf 'SUPERPOWERS_EVAL_REPETITIONS must be a positive integer\n' >&2; exit 2; }
[[ "$CALL_TIMEOUT_SECONDS" =~ ^[1-9][0-9]*$ ]] ||
  { printf 'SUPERPOWERS_EVAL_TIMEOUT_SECONDS must be a positive integer\n' >&2; exit 2; }

python3 - "$CASES" "$WORK_DIR/scenarios.json" <<'PY'
import json, sys
cases = json.load(open(sys.argv[1], encoding="utf-8"))
json.dump(
    [{"id": c["id"], "skill": c["skill"], "scenario": c["scenario"]} for c in cases],
    open(sys.argv[2], "w", encoding="utf-8"),
)
PY

prompt_file="$WORK_DIR/prompt.txt"
{
  printf '%s\n' \
    "Act as a Superpowers dispatch controller." \
    "Read only the named SKILL.md files in this checkout when deciding." \
    "For each supplied scenario, choose the native Codex role instructed by the skill." \
    "If the scenario says that required role is unavailable, action must be stop." \
    "If the scenario says no native Superpowers roles are exposed at all, follow the skill's generic platform-neutral dispatch and set role to none with action dispatch." \
    "Return only the output-schema JSON."
  cat "$WORK_DIR/scenarios.json"
} >"$prompt_file"

for repetition in $(seq 1 "$REPETITIONS"); do
  printf 'Routing eval repetition %s/%s...\n' "$repetition" "$REPETITIONS"
  if ! timeout "$CALL_TIMEOUT_SECONDS" \
    "$CODEX_BIN" -a never exec --ephemeral --ignore-rules \
      --sandbox read-only \
      -C "$REPO_ROOT" -m "$EVAL_MODEL" \
      -c 'model_reasoning_effort="medium"' \
      --output-schema "$SCHEMA" \
      --output-last-message "$WORK_DIR/result-$repetition.json" \
      - <"$prompt_file" >"$WORK_DIR/codex-$repetition.log" 2>&1; then
    cat "$WORK_DIR/codex-$repetition.log" >&2
    exit 1
  fi
  printf 'Routing eval repetition %s/%s complete.\n' "$repetition" "$REPETITIONS"
done

python3 - "$CASES" "$WORK_DIR" "$MODE" "$REPETITIONS" <<'PY'
import json, sys
expected = {c["id"]: (c["role"], c["action"]) for c in json.load(open(sys.argv[1]))}
work_dir, mode, repetitions = sys.argv[2], sys.argv[3], int(sys.argv[4])
results = []
for repetition in range(1, repetitions + 1):
    payload = json.load(open(f"{work_dir}/result-{repetition}.json"))
    actual = {d["id"]: (d["role"], d["action"]) for d in payload["decisions"]}
    mismatches = {
        key: {"expected": expected[key], "actual": actual.get(key)}
        for key in expected if actual.get(key) != expected[key]
    }
    results.append(mismatches)
if mode == "--baseline":
    for index, mismatches in enumerate(results, start=1):
        if len(mismatches) < 5:
            raise SystemExit(
                f"baseline repetition {index} unexpectedly encoded routing; "
                f"only {len(mismatches)} mismatches"
            )
        print(f"Baseline repetition {index} mismatches:")
        print(json.dumps(mismatches, indent=2))
    print(
        f"Baseline captured: {sum(map(len, results))} mismatches across "
        f"{repetitions} fresh-context calls"
    )
elif any(results):
    raise SystemExit("routing mismatches: " + json.dumps(results, indent=2))
else:
    print(
        f"Codex AI role routing valid: "
        f"{len(expected) * repetitions} decisions across {repetitions} calls"
    )
PY
