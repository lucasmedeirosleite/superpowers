# Codex AI Roles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a personal Codex variant of Superpowers with explicit GPT-5.6 and Kimi K3 subagent roles, lifecycle-aware dispatch routing, and a reversible managed-link installer.

**Architecture:** Keep Superpowers' primary-thread workflow unchanged and document model recommendations for those phases. Add Codex-native TOML roles only for actual subagent boundaries, teach the dispatching skills to select them, and install the source checkout through the existing local marketplace plus an ownership-tracked link under the Codex agents directory.

**Tech Stack:** Codex CLI 0.145.0+, TOML role configuration, Python 3.11+ standard library (`tomllib`, `json`, `unittest`), Bash, existing local marketplace metadata.

## Global Constraints

- Preserve the existing Superpowers lifecycle and its human approval gates.
- Use Codex-native roles only where Codex actually dispatches a subagent.
- Give primary-thread phases documented model recommendations because native roles cannot change the model of the already-running parent agent.
- Use GPT-5.6 Sol selectively for architecture and final judgment, not as a universal default.
- No GPT-5.6 role may exceed `high` reasoning.
- Kimi K3 may use `max` reasoning and is the only model allowed to do so.
- `superpowers-implementer` specifically uses GPT-5.6 Terra at `high`.
- Installation must be reversible, idempotent, and must not overwrite or silently remove an existing Superpowers installation.
- Before any live verification that requires uninstalling the currently installed Superpowers plugin, Codex must ask the user for approval at that moment.
- Canonical models are `gpt-5.6-sol`, `gpt-5.6-terra`, `gpt-5.6-luna`, and `kimi-oauth/k3`.
- Native role files and installer scripts remain source-checkout assets; the standard packaged plugin must continue excluding top-level `agents/`, `scripts/`, `tests/`, and `docs/`.

---

## File Structure

### Role configuration and validation

- Create `agents/superpowers-explorer.toml` — narrow lookup role.
- Create `agents/superpowers-investigator.toml` — independent root-cause role.
- Create `agents/superpowers-implementer-mechanical.toml` — bounded mechanical implementation role.
- Create `agents/superpowers-implementer.toml` — normal multi-file implementation role.
- Create `agents/superpowers-implementer-complex.toml` — architectural implementation role.
- Create `agents/superpowers-task-reviewer.toml` — first task-review gate.
- Create `agents/superpowers-re-reviewer.toml` — scoped fix verification role.
- Create `agents/superpowers-recovery.toml` — fresh repeated-failure recovery role.
- Create `agents/superpowers-final-reviewer.toml` — whole-branch final review role.
- Create `scripts/validate-codex-ai-roles.py` — parse roles, enforce the approved matrix, and optionally verify a Codex model catalog.
- Create `tests/codex/test-ai-roles.py` — deterministic role and catalog validation tests.

### Workflow routing

- Create `docs/superpowers/codex-ai-roles.md` — lifecycle recommendations, native role matrix, routing rules, failure behavior, and setup guide.
- Modify `skills/subagent-driven-development/SKILL.md` — select native roles at implementer, reviewer, recovery, and final-review dispatches.
- Modify `skills/dispatching-parallel-agents/SKILL.md` — select explorer, investigator, or implementer roles by delegated purpose.
- Modify `skills/requesting-code-review/SKILL.md` — select task, scoped re-review, or final reviewer roles.
- Create `tests/codex/ai-role-routing-cases.json` — representative routing scenarios and expected decisions.
- Create `tests/codex/ai-role-routing-output.schema.json` — constrained eval response shape.
- Create `tests/codex/run-ai-role-routing-eval.sh` — five fresh-context baseline and post-change instruction-eval calls.

### Managed installation

- Create `scripts/codex-variant-common.sh` — shared version, JSON, ownership, and state helpers.
- Create `scripts/install-codex-variant.sh` — preflight, marketplace/plugin registration, agents link, and durable ownership state.
- Create `scripts/uninstall-codex-variant.sh` — remove only state proven to be owned by this checkout.
- Create `tests/codex/fixtures/fake-codex.sh` — stateful Codex CLI double.
- Create `tests/codex/test-codex-variant-installer.sh` — fresh, repeated, conflict, failure, and uninstall cases.

### Packaging and entry-point documentation

- Modify `tests/codex/test-package-codex-plugin.sh` — explicitly assert that top-level native roles remain outside the packaged plugin.
- Modify `README.md` — link to the personal Codex AI-role setup guide without presenting it as a universal upstream default.

---

### Task 1: Define and statically validate native Codex roles

**Files:**
- Create: `agents/superpowers-explorer.toml`
- Create: `agents/superpowers-investigator.toml`
- Create: `agents/superpowers-implementer-mechanical.toml`
- Create: `agents/superpowers-implementer.toml`
- Create: `agents/superpowers-implementer-complex.toml`
- Create: `agents/superpowers-task-reviewer.toml`
- Create: `agents/superpowers-re-reviewer.toml`
- Create: `agents/superpowers-recovery.toml`
- Create: `agents/superpowers-final-reviewer.toml`
- Create: `scripts/validate-codex-ai-roles.py`
- Create: `tests/codex/test-ai-roles.py`

**Interfaces:**
- Consumes: Codex role fields `name`, `description`, `model`, `model_reasoning_effort`, `developer_instructions`, and optional `nickname_candidates`.
- Produces: `load_roles(roles_dir: pathlib.Path) -> dict[str, dict]`.
- Produces: `validate_roles(roles: dict[str, dict]) -> list[str]`.
- Produces: `validate_catalog(roles: dict[str, dict], catalog: dict) -> list[str]`.
- Produces: CLI exit `0` with `Codex AI roles valid` or exit `1` with one `ERROR: ...` line per violation.

- [ ] **Step 1: Write the failing role-validator tests**

Create `tests/codex/test-ai-roles.py` with an import-by-path helper and these
cases:

```python
#!/usr/bin/env python3
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

REPO_ROOT = Path(__file__).resolve().parents[2]
VALIDATOR_PATH = REPO_ROOT / "scripts" / "validate-codex-ai-roles.py"


def load_validator():
    spec = importlib.util.spec_from_file_location("codex_ai_roles", VALIDATOR_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class CodexAIRolesTest(unittest.TestCase):
    def setUp(self):
        self.validator = load_validator()

    def test_repository_roles_match_approved_matrix(self):
        roles = self.validator.load_roles(REPO_ROOT / "agents")
        self.assertEqual([], self.validator.validate_roles(roles))
        self.assertEqual(
            {
                "superpowers-explorer": ("gpt-5.6-luna", "low"),
                "superpowers-investigator": ("kimi-oauth/k3", "max"),
                "superpowers-implementer-mechanical": ("gpt-5.6-luna", "medium"),
                "superpowers-implementer": ("gpt-5.6-terra", "high"),
                "superpowers-implementer-complex": ("gpt-5.6-sol", "high"),
                "superpowers-task-reviewer": ("gpt-5.6-terra", "high"),
                "superpowers-re-reviewer": ("gpt-5.6-terra", "medium"),
                "superpowers-recovery": ("kimi-oauth/k3", "max"),
                "superpowers-final-reviewer": ("gpt-5.6-sol", "high"),
            },
            {
                name: (role["model"], role["model_reasoning_effort"])
                for name, role in roles.items()
            },
        )

    def test_rejects_duplicate_declared_name(self):
        roles = {
            "first": self.validator.expected_role("superpowers-explorer"),
            "second": self.validator.expected_role("superpowers-explorer"),
        }
        errors = self.validator.validate_roles(roles)
        self.assertTrue(any("duplicate role name" in error for error in errors))

    def test_rejects_gpt_reasoning_above_high(self):
        role = self.validator.expected_role("superpowers-implementer")
        role["model_reasoning_effort"] = "max"
        errors = self.validator.validate_roles({"superpowers-implementer": role})
        self.assertTrue(any("GPT-5.6 reasoning must not exceed high" in error for error in errors))

    def test_rejects_max_for_non_kimi_model(self):
        role = self.validator.expected_role("superpowers-final-reviewer")
        role["model_reasoning_effort"] = "max"
        errors = self.validator.validate_roles({"superpowers-final-reviewer": role})
        self.assertTrue(any("only Kimi K3 may use max" in error for error in errors))

    def test_catalog_must_contain_each_model_and_effort(self):
        roles = {
            "superpowers-investigator":
                self.validator.expected_role("superpowers-investigator")
        }
        catalog = {
            "models": [{
                "slug": "kimi-oauth/k3",
                "supported_reasoning_levels": [{"effort": "high"}],
            }]
        }
        errors = self.validator.validate_catalog(roles, catalog)
        self.assertEqual(
            ["superpowers-investigator: kimi-oauth/k3 does not support reasoning max"],
            errors,
        )


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the test and verify the validator is absent**

Run:

```bash
python3 tests/codex/test-ai-roles.py
```

Expected: FAIL while importing
`scripts/validate-codex-ai-roles.py`.

- [ ] **Step 3: Implement the validator's approved contract**

Create `scripts/validate-codex-ai-roles.py` with this canonical mapping and
validation behavior:

```python
#!/usr/bin/env python3
import argparse
import json
from pathlib import Path
import sys
import tomllib

EXPECTED = {
    "superpowers-explorer": ("gpt-5.6-luna", "low"),
    "superpowers-investigator": ("kimi-oauth/k3", "max"),
    "superpowers-implementer-mechanical": ("gpt-5.6-luna", "medium"),
    "superpowers-implementer": ("gpt-5.6-terra", "high"),
    "superpowers-implementer-complex": ("gpt-5.6-sol", "high"),
    "superpowers-task-reviewer": ("gpt-5.6-terra", "high"),
    "superpowers-re-reviewer": ("gpt-5.6-terra", "medium"),
    "superpowers-recovery": ("kimi-oauth/k3", "max"),
    "superpowers-final-reviewer": ("gpt-5.6-sol", "high"),
}
GPT_EFFORTS = {"low": 0, "medium": 1, "high": 2}
REQUIRED_FIELDS = {
    "name",
    "description",
    "model",
    "model_reasoning_effort",
    "developer_instructions",
}


def expected_role(name):
    model, effort = EXPECTED[name]
    return {
        "name": name,
        "description": "test description",
        "model": model,
        "model_reasoning_effort": effort,
        "developer_instructions": "test instructions",
    }


def load_roles(roles_dir):
    roles = {}
    for path in sorted(Path(roles_dir).glob("*.toml")):
        roles[path.stem] = tomllib.loads(path.read_text(encoding="utf-8"))
    return roles


def validate_roles(roles):
    errors = []
    declared_names = [role.get("name") for role in roles.values()]
    if len(declared_names) != len(set(declared_names)):
        errors.append("duplicate role name")
    if set(roles) != set(EXPECTED):
        errors.append(
            "role filenames differ: expected "
            + ", ".join(sorted(EXPECTED))
            + "; got "
            + ", ".join(sorted(roles))
        )
    for filename, role in sorted(roles.items()):
        missing = sorted(REQUIRED_FIELDS - role.keys())
        if missing:
            errors.append(f"{filename}: missing fields {', '.join(missing)}")
            continue
        if role["name"] != filename:
            errors.append(f"{filename}: declared name is {role['name']}")
        expected = EXPECTED.get(filename)
        actual = (role["model"], role["model_reasoning_effort"])
        if expected is not None and actual != expected:
            errors.append(f"{filename}: expected {expected}, got {actual}")
        if not role["description"].strip() or not role["developer_instructions"].strip():
            errors.append(f"{filename}: description and instructions must be non-empty")
        effort = role["model_reasoning_effort"]
        if role["model"].startswith("gpt-5.6-") and effort not in GPT_EFFORTS:
            errors.append(f"{filename}: GPT-5.6 reasoning must not exceed high")
        if effort == "max" and role["model"] != "kimi-oauth/k3":
            errors.append(f"{filename}: only Kimi K3 may use max")
    return errors


def validate_catalog(roles, catalog):
    errors = []
    models = {model.get("slug"): model for model in catalog.get("models", [])}
    for name, role in sorted(roles.items()):
        model = models.get(role["model"])
        if model is None:
            errors.append(f"{name}: model {role['model']} is unavailable")
            continue
        efforts = {
            item["effort"]
            for item in model.get("supported_reasoning_levels", [])
            if "effort" in item
        }
        if role["model_reasoning_effort"] not in efforts:
            errors.append(
                f"{name}: {role['model']} does not support reasoning "
                f"{role['model_reasoning_effort']}"
            )
    return errors
```

Complete the CLI with:

```python
def parse_args():
    repo_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument("--roles-dir", type=Path, default=repo_root / "agents")
    parser.add_argument("--catalog", type=Path)
    return parser.parse_args()


def main():
    args = parse_args()
    roles = load_roles(args.roles_dir)
    errors = validate_roles(roles)
    if args.catalog:
        with args.catalog.open(encoding="utf-8") as handle:
            errors.extend(validate_catalog(roles, json.load(handle)))
    if errors:
        for error in sorted(errors):
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("Codex AI roles valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

- [ ] **Step 4: Create the nine exact role files**

Every file follows this shape:

```toml
name = "superpowers-explorer"
description = "Use for a narrow, read-only codebase lookup with a crisp question and bounded scope."
model = "gpt-5.6-luna"
model_reasoning_effort = "low"
nickname_candidates = ["Scout", "Locator", "Index"]
developer_instructions = """
Answer one bounded repository question. Read only the files needed to establish the answer. Return concise evidence with paths and line references. Do not edit files, broaden the task, or make architectural decisions. If the question is not bounded, return NEEDS_CONTEXT and state the missing boundary.
"""
```

Use the following exact values for the other eight files:

| File/name | Description | Model/effort | Nicknames | Developer instruction |
|---|---|---|---|---|
| `superpowers-investigator` | Use for independent root-cause analysis with multiple plausible hypotheses or broad evidence gathering. | `kimi-oauth/k3` / `max` | `["Analyst", "Tracer", "Sleuth"]` | Investigate before proposing a fix. Reproduce or inspect evidence, form competing hypotheses, test them in descending likelihood, and identify the root cause. Return evidence, eliminated hypotheses, root cause, and the smallest justified fix direction. Do not edit unless the dispatch explicitly authorizes implementation. |
| `superpowers-implementer-mechanical` | Use for complete, low-ambiguity implementation normally confined to one or two files. | `gpt-5.6-luna` / `medium` | `["Builder", "Mechanic", "Assembler"]` | Read the supplied task brief first and treat it as the complete requirement. Follow test-driven development, keep changes within the stated files and interfaces, run the named tests, self-review the diff, commit the task, write the requested report file, and return only the requested short status contract. Escalate ambiguity instead of inventing requirements. |
| `superpowers-implementer` | Use for normal multi-file implementation and integration work. | `gpt-5.6-terra` / `high` | `["Integrator", "Maker", "Engineer"]` | Read the supplied task brief first. Preserve existing architecture and interfaces, use test-driven development, implement the smallest complete multi-file change, run focused and integration tests, self-review for scope and regressions, commit the task, write the requested report file, and return only the requested short status contract. Report NEEDS_CONTEXT or BLOCKED when the brief cannot safely govern the work. |
| `superpowers-implementer-complex` | Use for architectural, broad, cross-cutting, or materially ambiguous implementation. | `gpt-5.6-sol` / `high` | `["Architect", "Lead", "Systems"]` | Read the supplied task brief and relevant approved design. Resolve implementation details within the approved architecture, preserve boundaries, use test-driven development, and keep the change no broader than required. Run focused and broad regression tests, self-review architectural effects, commit, write the requested report, and surface any design contradiction to the controller instead of silently choosing a new design. |
| `superpowers-task-reviewer` | Use for the fresh first review of one completed implementation task. | `gpt-5.6-terra` / `high` | `["Reviewer", "Inspector", "Gate"]` | Independently review the supplied task brief, implementer report, constraints, and review package. Verify spec compliance first, then code quality. Read the actual diff and relevant code. Report both verdicts, evidence, and findings classified Critical, Important, or Minor. Label plan-mandated defects explicitly and never weaken a finding to avoid a fix loop. Do not edit code. |
| `superpowers-re-reviewer` | Use for scoped verification that known findings were fixed without regression. | `gpt-5.6-terra` / `medium` | `["Verifier", "Checker", "Recheck"]` | Review only the supplied open findings and fix-range package. Verdict each finding ADDRESSED or NOT ADDRESSED with evidence, and report new Critical or Important breakage introduced by the fix diff. Treat unrelated observations as out of scope. Do not reopen the full task review and do not edit code. |
| `superpowers-recovery` | Use for a fresh recovery attempt after repeated failed fix rounds or a final-review fix wave needing independent diagnosis. | `kimi-oauth/k3` / `max` | `["Recovery", "Breaker", "FreshEyes"]` | Assume prior attempts may share a faulty premise. Read the task brief, accumulated report, exact open findings, and latest diff. Reconstruct the failure independently, implement the smallest correct recovery with covering tests, append the fix report, commit the change, and return the requested short contract. Preserve approved scope and escalate a broken plan rather than working around it. |
| `superpowers-final-reviewer` | Use for plan-wide whole-branch review and release-level judgment. | `gpt-5.6-sol` / `high` | `["Auditor", "Release", "Final"]` | Review the whole branch against the approved design, plan, global constraints, ledger rulings, and branch review package. Check cross-task integration, omissions, regressions, and deferred or parked findings. Return findings first with severity and evidence, then a release verdict. Do not edit code and do not inherit the controller's conclusions without verification. |

- [ ] **Step 5: Run static and live-catalog validation**

Run:

```bash
python3 tests/codex/test-ai-roles.py
catalog_file="$(mktemp)"
codex debug models >"$catalog_file"
python3 scripts/validate-codex-ai-roles.py --catalog "$catalog_file"
rm "$catalog_file"
```

Expected:

```text
.....
OK
Codex AI roles valid
```

- [ ] **Step 6: Commit the role contract**

```bash
git add agents scripts/validate-codex-ai-roles.py tests/codex/test-ai-roles.py
git commit -m "feat: define Codex AI roles"
```

---

### Task 2: Route Superpowers dispatches through the native roles

**Files:**
- Create: `docs/superpowers/codex-ai-roles.md`
- Modify: `skills/subagent-driven-development/SKILL.md`
- Modify: `skills/dispatching-parallel-agents/SKILL.md`
- Modify: `skills/requesting-code-review/SKILL.md`
- Create: `tests/codex/ai-role-routing-cases.json`
- Create: `tests/codex/ai-role-routing-output.schema.json`
- Create: `tests/codex/run-ai-role-routing-eval.sh`
- Modify: `tests/codex/test-ai-roles.py`
- Modify: `scripts/validate-codex-ai-roles.py`

**Interfaces:**
- Consumes: The nine native role names and the existing Superpowers dispatch boundaries.
- Produces: `validate_references(roles, guide_path, skills_root) -> list[str]`.
- Produces: eval output `{"decisions": [{"id": str, "role": str, "action": "dispatch"|"stop"}]}`.
- Produces: routing rules that require an explicit stop if a role is unavailable.

- [ ] **Step 1: Add the routing cases and constrained output schema**

Create `tests/codex/ai-role-routing-cases.json`:

```json
[
  {"id":"narrow-lookup","skill":"dispatching-parallel-agents","scenario":"Locate the one function that parses the SDD ledger. Read-only, no architectural analysis.","role":"superpowers-explorer","action":"dispatch"},
  {"id":"root-cause","skill":"dispatching-parallel-agents","scenario":"Three independent clues point to a nondeterministic cache bug. Investigate competing root-cause hypotheses without editing.","role":"superpowers-investigator","action":"dispatch"},
  {"id":"mechanical-implementation","skill":"subagent-driven-development","scenario":"The task gives complete code and tests for a one-file parser change.","role":"superpowers-implementer-mechanical","action":"dispatch"},
  {"id":"normal-implementation","skill":"subagent-driven-development","scenario":"The task coordinates parsing, storage, and CLI output across four files using established interfaces.","role":"superpowers-implementer","action":"dispatch"},
  {"id":"complex-implementation","skill":"subagent-driven-development","scenario":"The task changes an architectural boundary shared by multiple workflows and requires approved-design judgment.","role":"superpowers-implementer-complex","action":"dispatch"},
  {"id":"task-review","skill":"subagent-driven-development","scenario":"The implementer finished one plan task and produced its brief, report, and review package.","role":"superpowers-task-reviewer","action":"dispatch"},
  {"id":"scoped-re-review","skill":"subagent-driven-development","scenario":"Verify two known findings against only the latest fix diff.","role":"superpowers-re-reviewer","action":"dispatch"},
  {"id":"round-four-recovery","skill":"subagent-driven-development","scenario":"The original implementer failed three reviewed fix rounds; begin fix round four with persisted evidence.","role":"superpowers-recovery","action":"dispatch"},
  {"id":"final-review","skill":"requesting-code-review","scenario":"All plan tasks are complete; review the whole branch before finishing.","role":"superpowers-final-reviewer","action":"dispatch"},
  {"id":"missing-role","skill":"subagent-driven-development","scenario":"A normal multi-file task needs superpowers-implementer, but Codex reports that configured role unavailable.","role":"superpowers-implementer","action":"stop"}
]
```

Create `tests/codex/ai-role-routing-output.schema.json`:

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": ["decisions"],
  "properties": {
    "decisions": {
      "type": "array",
      "minItems": 10,
      "maxItems": 10,
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["id", "role", "action"],
        "properties": {
          "id": {"type": "string"},
          "role": {"type": "string"},
          "action": {"type": "string", "enum": ["dispatch", "stop"]}
        }
      }
    }
  }
}
```

- [ ] **Step 2: Write the eval runner and capture the baseline before editing skills**

Create `tests/codex/run-ai-role-routing-eval.sh`. It must:

```bash
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
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

[[ "$REPETITIONS" =~ ^[1-9][0-9]*$ ]] ||
  { printf 'SUPERPOWERS_EVAL_REPETITIONS must be a positive integer\n' >&2; exit 2; }

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
    "Return only the output-schema JSON."
  cat "$WORK_DIR/scenarios.json"
} >"$prompt_file"

for repetition in $(seq 1 "$REPETITIONS"); do
  "$CODEX_BIN" -a never exec --ephemeral --ignore-rules \
    --sandbox read-only \
    -C "$REPO_ROOT" -m "$EVAL_MODEL" \
    -c 'model_reasoning_effort="medium"' \
    --output-schema "$SCHEMA" \
    --output-last-message "$WORK_DIR/result-$repetition.json" \
    - <"$prompt_file"
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
```

Run before changing the skills:

```bash
bash tests/codex/run-ai-role-routing-eval.sh --baseline
```

Expected: five fresh-context calls pass with at least five mismatches each.
Read every printed mismatch before editing the skills; this proves the current
instructions do not already encode the new routing behavior and records the
baseline failure shapes.

- [ ] **Step 3: Write the lifecycle and routing guide**

Create `docs/superpowers/codex-ai-roles.md` with:

```markdown
# Codex AI Roles

This personal Superpowers variant separates primary-thread model
recommendations from enforceable native subagent roles. Native roles apply
only when Codex spawns a subagent.

## Primary Lifecycle

| Phase | Workflow | Model | Reasoning |
|---|---|---|---|
| Designer | brainstorming | gpt-5.6-sol | high |
| Planner | writing-plans | gpt-5.6-sol | high |
| Controller | SDD or executing-plans coordination | gpt-5.6-sol | high |
| Inline executor | executing-plans and TDD | gpt-5.6-terra | medium |
| Systematic debugger | systematic-debugging | gpt-5.6-sol | high |
| Review-feedback evaluator | receiving-code-review | gpt-5.6-terra | high |
| Workspace/completion operator | worktrees, verification, branch finishing | gpt-5.6-luna | medium |
| Skill author | writing-skills | gpt-5.6-sol | high |

Designer is the brainstorming lifecycle phase. It remains in the primary
thread, so it is a recommendation rather than a native role.

## Native Subagent Roles

| Role | Model | Reasoning | Purpose |
|---|---|---|---|
| `superpowers-explorer` | `gpt-5.6-luna` | `low` | Narrow read-only lookup |
| `superpowers-investigator` | `kimi-oauth/k3` | `max` | Root-cause investigation |
| `superpowers-implementer-mechanical` | `gpt-5.6-luna` | `medium` | Complete low-ambiguity work in 1-2 files |
| `superpowers-implementer` | `gpt-5.6-terra` | `high` | Normal multi-file implementation |
| `superpowers-implementer-complex` | `gpt-5.6-sol` | `high` | Architectural or broad implementation |
| `superpowers-task-reviewer` | `gpt-5.6-terra` | `high` | Fresh first task review |
| `superpowers-re-reviewer` | `gpt-5.6-terra` | `medium` | Scoped fix verification |
| `superpowers-recovery` | `kimi-oauth/k3` | `max` | Fresh recovery after repeated failures |
| `superpowers-final-reviewer` | `gpt-5.6-sol` | `high` | Whole-branch final review |

## Dispatch Routing

1. Narrow repository lookup uses `superpowers-explorer`.
2. Root-cause analysis with competing hypotheses uses
   `superpowers-investigator`.
3. Complete, low-ambiguity work in 1-2 files uses
   `superpowers-implementer-mechanical`.
4. Normal multi-file work uses `superpowers-implementer`.
5. Architectural, broad, or materially ambiguous work uses
   `superpowers-implementer-complex`.
6. First task review uses `superpowers-task-reviewer`.
7. Fix-only verification uses `superpowers-re-reviewer`.
8. Fix rounds 1-3 retain the original implementer and role.
9. Fix rounds 4-5 use a fresh `superpowers-recovery` agent for each round.
10. Whole-branch final review uses `superpowers-final-reviewer`.
11. The single final-review fix wave uses `superpowers-recovery`, followed by
    `superpowers-re-reviewer`.

If a requested role, model, or reasoning level is unavailable, stop and
report the role, configured model and effort, availability error, and
corrective action or explicit user-selected alternative. Never silently
inherit the parent model or substitute another role.
```

This task's guide ends after the fallback behavior. Installation,
uninstallation, restart, and packaging-boundary sections are added as a
separate independently reviewed documentation deliverable.

- [ ] **Step 4: Add Codex routing to the three dispatching skills**

In `skills/subagent-driven-development/SKILL.md`, keep the generic tier
guidance and add this Codex-specific recipe immediately after it:

```markdown
### Codex native role routing

When the harness exposes the Superpowers Codex roles, specify the role on
every spawn:

- complete, low-ambiguity work in 1-2 files:
  `superpowers-implementer-mechanical`
- normal multi-file implementation or integration:
  `superpowers-implementer`
- architectural, broad, or materially ambiguous implementation:
  `superpowers-implementer-complex`
- first task review: `superpowers-task-reviewer`
- scoped fix re-review: `superpowers-re-reviewer`
- fix rounds 4-5: a fresh `superpowers-recovery` agent for each round
- whole-branch final review: `superpowers-final-reviewer`
- one final-review fix wave: `superpowers-recovery`

Rounds 1-3 resume the original implementation agent, preserving the role
selected for that task. Selecting a native role satisfies the explicit-model
requirement because the role fixes both model and reasoning effort.

If a role or its configured model is unavailable, STOP that dispatch. Report
the requested role, configured model and effort, the availability error, and
the corrective action or user-selected alternative. Never silently inherit
the parent model or substitute another role.
```

Update the process graph labels and prose so rounds 4-5 say
`superpowers-recovery`, task review says `superpowers-task-reviewer`, scoped
re-review says `superpowers-re-reviewer`, and final review says
`superpowers-final-reviewer`. Preserve the five-round breaker and all existing
human adjudication behavior.

In `skills/dispatching-parallel-agents/SKILL.md`, add:

```markdown
### Codex native role routing

Choose by the delegated outcome:

- narrow read-only lookup: `superpowers-explorer`
- root-cause analysis or broad independent investigation:
  `superpowers-investigator`
- bounded code change: select `superpowers-implementer-mechanical`,
  `superpowers-implementer`, or `superpowers-implementer-complex` using the
  same complexity signals as subagent-driven-development

All parallel calls must name their role. If a required role is unavailable,
stop that dispatch and report the missing role; do not fall back silently.
```

Replace the three `general-purpose` examples with purpose-appropriate role
names.

In `skills/requesting-code-review/SKILL.md`, replace the unconditional
`general-purpose` instruction with:

```markdown
**2. Choose and dispatch the reviewer:**

- one completed plan task: `superpowers-task-reviewer`
- a fix-only diff with known findings: `superpowers-re-reviewer`
- a major feature or whole branch before merge: `superpowers-final-reviewer`

Fill the template at [code-reviewer.md](code-reviewer.md). If the selected
role is unavailable, stop and report its configured model and effort instead
of dispatching an untyped reviewer.
```

- [ ] **Step 5: Extend deterministic validation to documentation and skills**

Add `validate_references` to `scripts/validate-codex-ai-roles.py`. It reads the
guide and the three dispatching skills, then reports:

```python
def validate_references(roles, guide_path, skills_root):
    errors = []
    guide = Path(guide_path).read_text(encoding="utf-8")
    skill_names = [
        "subagent-driven-development",
        "dispatching-parallel-agents",
        "requesting-code-review",
    ]
    skill_text = "\n".join(
        (Path(skills_root) / name / "SKILL.md").read_text(encoding="utf-8")
        for name in skill_names
    )
    for role_name, role in sorted(roles.items()):
        row = f"| `{role_name}` | `{role['model']}` | `{role['model_reasoning_effort']}` |"
        if row not in guide:
            errors.append(f"{role_name}: guide matrix does not match role TOML")
        if role_name not in skill_text:
            errors.append(f"{role_name}: no dispatching skill references role")
    if "Never silently inherit" not in skill_text:
        errors.append("dispatching skills do not prohibit silent fallback")
    return errors
```

Add `--guide` and `--skills-root` CLI arguments and add tests for a mismatched
guide row, a missing skill reference, and the repository's real guide/skill
set.

- [ ] **Step 6: Run post-change static and behavioral tests**

Run:

```bash
python3 tests/codex/test-ai-roles.py
python3 scripts/validate-codex-ai-roles.py \
  --guide docs/superpowers/codex-ai-roles.md \
  --skills-root skills
bash tests/codex/run-ai-role-routing-eval.sh --post-change
```

Expected:

```text
OK
Codex AI roles valid
Codex AI role routing valid: 50 decisions across 5 calls
```

- [ ] **Step 7: Commit the routing behavior**

```bash
git add docs/superpowers/codex-ai-roles.md \
  skills/subagent-driven-development/SKILL.md \
  skills/dispatching-parallel-agents/SKILL.md \
  skills/requesting-code-review/SKILL.md \
  scripts/validate-codex-ai-roles.py \
  tests/codex/test-ai-roles.py \
  tests/codex/ai-role-routing-cases.json \
  tests/codex/ai-role-routing-output.schema.json \
  tests/codex/run-ai-role-routing-eval.sh
git commit -m "feat: route Codex subagents by AI role"
```

---

### Task 3: Add the ownership-safe Codex variant installer

**Files:**
- Create: `scripts/codex-variant-common.sh`
- Create: `scripts/install-codex-variant.sh`
- Create: `scripts/uninstall-codex-variant.sh`
- Create: `tests/codex/fixtures/fake-codex.sh`
- Create: `tests/codex/test-codex-variant-installer.sh`

**Interfaces:**
- Consumes: `SUPERPOWERS_CODEX_BIN` override, default `codex`.
- Consumes: `SUPERPOWERS_CODEX_HOME` override, default `${CODEX_HOME:-$HOME/.codex}`.
- Consumes: `codex --version`, `codex debug models`, `codex plugin marketplace list --json`, and `codex plugin list --json`.
- Produces: managed link `$SUPERPOWERS_CODEX_HOME/agents/superpowers -> $REPO_ROOT/agents`.
- Produces: state `$SUPERPOWERS_CODEX_HOME/superpowers-variant-state.json`.
- Produces: local installation selector `superpowers@superpowers-dev`.
- Produces: exit `0` for fresh or idempotent success; exit `1` before mutation on ownership, official-plugin, version, model, or reasoning conflicts.

- [ ] **Step 1: Write the failing installer tests and fake Codex CLI**

Create `tests/codex/fixtures/fake-codex.sh` as this stateful command recorder:

```bash
#!/usr/bin/env bash
set -euo pipefail

STATE="${SUPERPOWERS_FAKE_CODEX_STATE:?}"

case "$*" in
  "--version")
    cat "$STATE/version"
    ;;
  "debug models")
    cat "$STATE/models.json"
    ;;
  "plugin marketplace list --json")
    cat "$STATE/marketplaces.json"
    ;;
  "plugin list --json")
    cat "$STATE/plugins.json"
    ;;
  "plugin marketplace add "*)
    printf '%s\n' "$*" >>"$STATE/commands.log"
    python3 - "$STATE/marketplaces.json" "$4" <<'PY'
import json, sys
payload = {"marketplaces": [{
    "name": "superpowers-dev",
    "root": sys.argv[2],
    "marketplaceSource": {"sourceType": "local", "source": sys.argv[2]},
}]}
json.dump(payload, open(sys.argv[1], "w", encoding="utf-8"))
PY
    printf '{"name":"superpowers-dev"}\n'
    ;;
  "plugin marketplace remove superpowers-dev --json")
    printf '%s\n' "$*" >>"$STATE/commands.log"
    printf '{"marketplaces":[]}\n' >"$STATE/marketplaces.json"
    printf '{"name":"superpowers-dev"}\n'
    ;;
  "plugin add superpowers@superpowers-dev --json")
    printf '%s\n' "$*" >>"$STATE/commands.log"
    python3 - "$STATE/plugins.json" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path, encoding="utf-8"))
data.setdefault("installed", []).append({
    "pluginId": "superpowers@superpowers-dev",
    "name": "superpowers",
    "marketplaceName": "superpowers-dev",
    "installed": True,
})
json.dump(data, open(path, "w", encoding="utf-8"))
PY
    printf '{"pluginId":"superpowers@superpowers-dev"}\n'
    ;;
  "plugin remove superpowers@superpowers-dev --json")
    printf '%s\n' "$*" >>"$STATE/commands.log"
    python3 - "$STATE/plugins.json" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path, encoding="utf-8"))
data["installed"] = [
    item for item in data.get("installed", [])
    if item.get("pluginId") != "superpowers@superpowers-dev"
]
json.dump(data, open(path, "w", encoding="utf-8"))
PY
    printf '{"pluginId":"superpowers@superpowers-dev"}\n'
    ;;
  *)
    printf 'unexpected fake Codex command: %s\n' "$*" >&2
    exit 2
    ;;
esac
```

Create `tests/codex/test-codex-variant-installer.sh` with this harness:

```bash
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
```

Append these exact cases:

```bash
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
[[ "$STATUS" -ne 0 && "$OUTPUT" == *"explicit user approval"* ]] ||
  fail "official plugin conflict diagnostic"
! grep -q 'plugin remove' "$FAKE_STATE/commands.log" ||
  fail "official plugin was automatically removed"

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
```

Make both test scripts executable:

```bash
chmod +x tests/codex/fixtures/fake-codex.sh \
  tests/codex/test-codex-variant-installer.sh
```

The official-plugin conflict case inspects both output and `commands.log`,
proving no automatic removal was attempted.

- [ ] **Step 2: Run the installer test and verify scripts are absent**

Run:

```bash
bash tests/codex/test-codex-variant-installer.sh
```

Expected: FAIL because `scripts/install-codex-variant.sh` does not exist.

- [ ] **Step 3: Implement shared preflight and ownership helpers**

Create `scripts/codex-variant-common.sh` with:

```bash
#!/usr/bin/env bash

variant_die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

variant_repo_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
  cd "$script_dir/.." && pwd
}

variant_codex_home() {
  printf '%s\n' "${SUPERPOWERS_CODEX_HOME:-${CODEX_HOME:-$HOME/.codex}}"
}

variant_codex_bin() {
  printf '%s\n' "${SUPERPOWERS_CODEX_BIN:-codex}"
}

variant_realpath() {
  python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

variant_version_at_least_0145() {
  python3 - "$1" <<'PY'
import re, sys
match = re.search(r"(\d+)\.(\d+)\.(\d+)", sys.argv[1])
raise SystemExit(0 if match and tuple(map(int, match.groups())) >= (0, 145, 0) else 1)
PY
}
```

Add these JSON and ownership helpers:

```bash
variant_marketplace_json() {
  env CODEX_HOME="$CODEX_HOME_PATH" \
    "$CODEX_BIN_PATH" plugin marketplace list --json
}

variant_plugins_json() {
  env CODEX_HOME="$CODEX_HOME_PATH" \
    "$CODEX_BIN_PATH" plugin list --json
}

variant_marketplace_root() {
  local json_file="$1"
  local marketplace_name="$2"
  python3 - "$json_file" "$marketplace_name" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
for item in data.get("marketplaces", []):
    if item.get("name") == sys.argv[2]:
        source = item.get("marketplaceSource", {}).get("source")
        print(source or item.get("root", ""))
        break
PY
}

variant_installed_superpowers_ids() {
  local json_file="$1"
  python3 - "$json_file" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
for item in data.get("installed", []):
    if item.get("name") == "superpowers" and item.get("installed", True):
        print(item["pluginId"])
PY
}

variant_plugin_is_installed() {
  local json_file="$1"
  local plugin_id="$2"
  python3 - "$json_file" "$plugin_id" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
raise SystemExit(0 if any(
    item.get("pluginId") == sys.argv[2] and item.get("installed", True)
    for item in data.get("installed", [])
) else 1)
PY
}

variant_state_value() {
  local state_file="$1"
  local key="$2"
  python3 - "$state_file" "$key" <<'PY'
import json, sys
value = json.load(open(sys.argv[1], encoding="utf-8"))[sys.argv[2]]
print(str(value).lower() if isinstance(value, bool) else value)
PY
}

variant_write_state_atomically() {
  local state_file="$1"
  local repo_root="$2"
  local agents_link="$3"
  local marketplace_added="$4"
  local plugin_added="$5"
  local agents_link_added="$6"
  local temp_state
  temp_state="$(mktemp "$(dirname "$state_file")/.superpowers-variant-state.XXXXXX")"
  python3 - "$temp_state" "$repo_root" "$agents_link" \
    "$marketplace_added" "$plugin_added" "$agents_link_added" <<'PY'
import json, sys
payload = {
    "schema": 1,
    "repo_root": sys.argv[2],
    "agents_link": sys.argv[3],
    "marketplace_name": "superpowers-dev",
    "marketplace_added": sys.argv[4] == "true",
    "plugin_id": "superpowers@superpowers-dev",
    "plugin_added": sys.argv[5] == "true",
    "agents_link_added": sys.argv[6] == "true",
}
with open(sys.argv[1], "w", encoding="utf-8") as handle:
    json.dump(payload, handle, indent=2)
    handle.write("\n")
PY
  mv "$temp_state" "$state_file"
}

variant_link_is_owned() {
  local target="$1"
  local source="$2"
  [[ -L "$target" ]] &&
    [[ "$(variant_realpath "$target")" == "$(variant_realpath "$source")" ]]
}
```

State writes go to a temporary file in the Codex home and move atomically into
place. The state schema is:

```json
{
  "schema": 1,
  "repo_root": "/absolute/source/checkout",
  "agents_link": "/absolute/codex/home/agents/superpowers",
  "marketplace_name": "superpowers-dev",
  "marketplace_added": true,
  "plugin_id": "superpowers@superpowers-dev",
  "plugin_added": true,
  "agents_link_added": true
}
```

Write the state immediately after each successful mutation with the ownership
booleans accumulated so far. This makes a partially completed install
recoverable without claiming pre-existing state.

- [ ] **Step 4: Implement the installer**

Create `scripts/install-codex-variant.sh` with this order:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/codex-variant-common.sh"

REPO_ROOT="$(variant_repo_root)"
CODEX_HOME_PATH="$(variant_codex_home)"
CODEX_BIN_PATH="$(variant_codex_bin)"
AGENTS_SOURCE="$REPO_ROOT/agents"
AGENTS_TARGET="$CODEX_HOME_PATH/agents/superpowers"
STATE_FILE="$CODEX_HOME_PATH/superpowers-variant-state.json"

command -v "$CODEX_BIN_PATH" >/dev/null 2>&1 ||
  variant_die "Codex executable not found: $CODEX_BIN_PATH"
command -v python3 >/dev/null 2>&1 ||
  variant_die "python3 is required"
[[ -d "$AGENTS_SOURCE" ]] ||
  variant_die "agents directory not found: $AGENTS_SOURCE"

version_output="$("$CODEX_BIN_PATH" --version)"
variant_version_at_least_0145 "$version_output" ||
  variant_die "Codex 0.145.0 or newer is required; found: $version_output"

catalog_file="$(mktemp)"
marketplaces_file="$(mktemp)"
plugins_file="$(mktemp)"
trap 'rm -f "$catalog_file" "$marketplaces_file" "$plugins_file"' EXIT
env CODEX_HOME="$CODEX_HOME_PATH" \
  "$CODEX_BIN_PATH" debug models >"$catalog_file"
python3 "$REPO_ROOT/scripts/validate-codex-ai-roles.py" \
  --roles-dir "$AGENTS_SOURCE" --catalog "$catalog_file" ||
  variant_die "configured Codex models or reasoning levels are unavailable"

variant_marketplace_json >"$marketplaces_file"
variant_plugins_json >"$plugins_file"

marketplace_added=false
plugin_added=false
agents_link_added=false

if [[ -e "$STATE_FILE" || -L "$STATE_FILE" ]]; then
  [[ -f "$STATE_FILE" && ! -L "$STATE_FILE" ]] ||
    variant_die "managed state is not a regular file: $STATE_FILE"
  [[ "$(variant_state_value "$STATE_FILE" schema)" == "1" ]] ||
    variant_die "unsupported managed state schema"
  [[ "$(variant_realpath "$(variant_state_value "$STATE_FILE" repo_root)")" == \
    "$(variant_realpath "$REPO_ROOT")" ]] ||
    variant_die "managed state belongs to a different checkout"
  [[ "$(variant_state_value "$STATE_FILE" agents_link)" == "$AGENTS_TARGET" ]] ||
    variant_die "managed state names an unexpected agents target"
  marketplace_added="$(variant_state_value "$STATE_FILE" marketplace_added)"
  plugin_added="$(variant_state_value "$STATE_FILE" plugin_added)"
  agents_link_added="$(variant_state_value "$STATE_FILE" agents_link_added)"
fi

while IFS= read -r plugin_id; do
  [[ -z "$plugin_id" || "$plugin_id" == "superpowers@superpowers-dev" ]] ||
    variant_die "installed Superpowers conflict: $plugin_id. Remove it only after explicit user approval; this installer will not remove it."
done < <(variant_installed_superpowers_ids "$plugins_file")

marketplace_root="$(variant_marketplace_root "$marketplaces_file" "superpowers-dev")"
if [[ -n "$marketplace_root" ]]; then
  [[ "$(variant_realpath "$marketplace_root")" == "$(variant_realpath "$REPO_ROOT")" ]] ||
    variant_die "superpowers-dev marketplace belongs to a different checkout: $marketplace_root"
fi

if [[ -e "$AGENTS_TARGET" || -L "$AGENTS_TARGET" ]]; then
  variant_link_is_owned "$AGENTS_TARGET" "$AGENTS_SOURCE" ||
    variant_die "agents target is not owned by this checkout: $AGENTS_TARGET"
fi

mkdir -p "$CODEX_HOME_PATH" "$CODEX_HOME_PATH/agents"

if [[ -z "$marketplace_root" ]]; then
  env CODEX_HOME="$CODEX_HOME_PATH" \
    "$CODEX_BIN_PATH" plugin marketplace add "$REPO_ROOT" --json
  marketplace_added=true
  variant_write_state_atomically "$STATE_FILE" "$REPO_ROOT" "$AGENTS_TARGET" \
    "$marketplace_added" "$plugin_added" "$agents_link_added"
fi

if ! variant_plugin_is_installed "$plugins_file" "superpowers@superpowers-dev"; then
  env CODEX_HOME="$CODEX_HOME_PATH" \
    "$CODEX_BIN_PATH" plugin add superpowers@superpowers-dev --json
  plugin_added=true
  variant_write_state_atomically "$STATE_FILE" "$REPO_ROOT" "$AGENTS_TARGET" \
    "$marketplace_added" "$plugin_added" "$agents_link_added"
fi

if [[ ! -L "$AGENTS_TARGET" ]]; then
  ln -s "$AGENTS_SOURCE" "$AGENTS_TARGET"
  agents_link_added=true
fi

variant_write_state_atomically "$STATE_FILE" "$REPO_ROOT" "$AGENTS_TARGET" \
  "$marketplace_added" "$plugin_added" "$agents_link_added"

printf 'Superpowers Codex variant installed from: %s\n' "$REPO_ROOT"
printf 'Plugin: superpowers@superpowers-dev\n'
printf 'Agents: %s -> %s\n' "$AGENTS_TARGET" "$AGENTS_SOURCE"
printf 'Start a new Codex session to load the roles.\n'
```

- [ ] **Step 5: Implement ownership-checked uninstall**

Create `scripts/uninstall-codex-variant.sh` with a complete ownership preflight
before its first removal:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/codex-variant-common.sh"

REPO_ROOT="$(variant_repo_root)"
CODEX_HOME_PATH="$(variant_codex_home)"
CODEX_BIN_PATH="$(variant_codex_bin)"
STATE_FILE="$CODEX_HOME_PATH/superpowers-variant-state.json"

if [[ ! -e "$STATE_FILE" && ! -L "$STATE_FILE" ]]; then
  printf 'No managed Superpowers Codex variant state found.\n'
  exit 0
fi

[[ -f "$STATE_FILE" && ! -L "$STATE_FILE" ]] ||
  variant_die "managed state is not a regular file: $STATE_FILE"
[[ "$(variant_state_value "$STATE_FILE" schema)" == "1" ]] ||
  variant_die "unsupported managed state schema"
[[ "$(variant_realpath "$(variant_state_value "$STATE_FILE" repo_root)")" == \
  "$(variant_realpath "$REPO_ROOT")" ]] ||
  variant_die "managed state belongs to a different checkout"

AGENTS_TARGET="$(variant_state_value "$STATE_FILE" agents_link)"
AGENTS_SOURCE="$REPO_ROOT/agents"
[[ "$AGENTS_TARGET" == "$CODEX_HOME_PATH/agents/superpowers" ]] ||
  variant_die "managed state names an unexpected agents target"
marketplace_added="$(variant_state_value "$STATE_FILE" marketplace_added)"
plugin_added="$(variant_state_value "$STATE_FILE" plugin_added)"
agents_link_added="$(variant_state_value "$STATE_FILE" agents_link_added)"

plugins_file="$(mktemp)"
marketplaces_file="$(mktemp)"
trap 'rm -f "$plugins_file" "$marketplaces_file"' EXIT
variant_plugins_json >"$plugins_file"
variant_marketplace_json >"$marketplaces_file"

if [[ "$agents_link_added" == "true" &&
  ( -e "$AGENTS_TARGET" || -L "$AGENTS_TARGET" ) ]]; then
  variant_link_is_owned "$AGENTS_TARGET" "$AGENTS_SOURCE" ||
    variant_die "refusing to remove foreign agents target: $AGENTS_TARGET"
fi

marketplace_root="$(variant_marketplace_root "$marketplaces_file" "superpowers-dev")"
if [[ "$marketplace_added" == "true" && -n "$marketplace_root" ]]; then
  [[ "$(variant_realpath "$marketplace_root")" == "$(variant_realpath "$REPO_ROOT")" ]] ||
    variant_die "refusing to remove foreign superpowers-dev marketplace"
fi

if [[ "$agents_link_added" == "true" && -L "$AGENTS_TARGET" ]]; then
  unlink "$AGENTS_TARGET"
fi
if [[ "$plugin_added" == "true" ]] &&
  variant_plugin_is_installed "$plugins_file" "superpowers@superpowers-dev"; then
  env CODEX_HOME="$CODEX_HOME_PATH" \
    "$CODEX_BIN_PATH" plugin remove superpowers@superpowers-dev --json
fi
if [[ "$marketplace_added" == "true" && -n "$marketplace_root" ]]; then
  env CODEX_HOME="$CODEX_HOME_PATH" \
    "$CODEX_BIN_PATH" plugin marketplace remove superpowers-dev --json
fi
rm -f "$STATE_FILE"

printf '%s\n' \
  "Managed Superpowers Codex variant removed. The official plugin was not installed or restored."
```

Do not use recursive removal. `unlink` targets only the validated agents link,
and `rm -f` targets only the validated state file.

- [ ] **Step 6: Run installer, syntax, and shell lint tests**

Run:

```bash
bash tests/codex/test-codex-variant-installer.sh
bash -n scripts/codex-variant-common.sh
bash -n scripts/install-codex-variant.sh
bash -n scripts/uninstall-codex-variant.sh
bash -n tests/codex/fixtures/fake-codex.sh
bash -n tests/codex/test-codex-variant-installer.sh
scripts/lint-shell.sh \
  scripts/codex-variant-common.sh \
  scripts/install-codex-variant.sh \
  scripts/uninstall-codex-variant.sh \
  tests/codex/fixtures/fake-codex.sh \
  tests/codex/test-codex-variant-installer.sh \
  tests/codex/run-ai-role-routing-eval.sh
```

Expected: all installer cases pass, all syntax checks exit `0`, and ShellCheck
reports no warning-or-higher findings.

- [ ] **Step 7: Commit the managed installer**

```bash
git add scripts/codex-variant-common.sh \
  scripts/install-codex-variant.sh \
  scripts/uninstall-codex-variant.sh \
  tests/codex/fixtures/fake-codex.sh \
  tests/codex/test-codex-variant-installer.sh
git commit -m "feat: add managed Codex variant installer"
```

---

### Task 4: Document setup and verify the complete variant

**Files:**
- Modify: `docs/superpowers/codex-ai-roles.md`
- Modify: `README.md`
- Modify: `tests/codex/test-package-codex-plugin.sh`

**Interfaces:**
- Consumes: `scripts/install-codex-variant.sh` and `scripts/uninstall-codex-variant.sh`.
- Produces: a user-facing setup path that clearly separates plugin installation from native role discovery.
- Produces: package regression evidence that source-only role assets remain excluded.
- Produces: a final isolated verification report without changing the active official plugin.

- [ ] **Step 1: Add the package-boundary regression assertion**

In `tests/codex/test-package-codex-plugin.sh`, extend
`unexpected_pattern` with `^agents/` and add:

```bash
assert_not_matches "$archive_paths" '(^|/)agents/.*\.toml$' \
  "archive excludes source-only native AI roles"
assert_not_matches "$archive_paths" '^scripts/(install|uninstall)-codex-variant\.sh$' \
  "archive excludes source-checkout variant installers"
```

Run:

```bash
bash tests/codex/test-package-codex-plugin.sh
```

Expected: PASS, including both new source-only assertions.

- [ ] **Step 2: Complete the setup and recovery guide**

Add these exact operational sections to
`docs/superpowers/codex-ai-roles.md`:

````markdown
## Install This Checkout

Run:

```bash
scripts/install-codex-variant.sh
```

The installer first checks Codex 0.145.0+, the four required model IDs and
their reasoning efforts, existing Superpowers plugins, the `superpowers-dev`
marketplace, and the agents target. It exits before mutation on any conflict.

Codex's plugin installation loads the Superpowers skills. The managed
`~/.codex/agents/superpowers` link separately exposes the native roles.
Start a new Codex session after installation.

## Existing Official Plugin

The installer never removes an existing official Superpowers plugin. If it
reports one, stop and obtain explicit user approval before running:

```bash
codex plugin remove superpowers@openai-curated
```

Then rerun the installer.

## Uninstall This Variant

Run:

```bash
scripts/uninstall-codex-variant.sh
```

The uninstaller removes only resources recorded as owned by this checkout.
It does not reinstall the official plugin.
````

Close the guide with:

```markdown
## Troubleshooting

| Diagnostic | Resolution |
|---|---|
| Codex 0.145.0 or newer is required | Upgrade Codex, then rerun the installer. |
| `kimi-oauth/k3` is unavailable | Configure the Kimi OAuth model provider so `codex debug models` lists `kimi-oauth/k3`. |
| A model does not support the configured reasoning effort | Update the local model catalog/provider configuration; do not lower or substitute a role silently. |
| `superpowers-dev` belongs to another checkout | Remove that marketplace only after confirming its owner, or use that checkout instead. |
| The agents target is not owned by this checkout | Inspect `~/.codex/agents/superpowers`; move or remove it yourself only after confirming its owner. |
| A role is missing in Codex after install | Confirm the managed link, then start a completely new Codex session because roles are discovered at session start. |
```

- [ ] **Step 3: Link the guide from the README**

Add a short Codex subsection near the existing installation/platform
documentation:

```markdown
### Personal Codex AI-role variant

This branch includes optional native Codex roles with explicit GPT-5.6 and
Kimi K3 assignments. See
[Codex AI Roles](docs/superpowers/codex-ai-roles.md) for the lifecycle matrix,
managed-link installation, and uninstall behavior.
```

- [ ] **Step 4: Run the complete non-destructive verification suite**

Run:

```bash
python3 tests/codex/test-ai-roles.py
catalog_file="$(mktemp)"
codex debug models >"$catalog_file"
python3 scripts/validate-codex-ai-roles.py \
  --catalog "$catalog_file" \
  --guide docs/superpowers/codex-ai-roles.md \
  --skills-root skills
rm "$catalog_file"
bash tests/codex/run-ai-role-routing-eval.sh --post-change
bash tests/codex/test-codex-variant-installer.sh
bash tests/codex/test-marketplace-manifest.sh
bash tests/codex/test-package-codex-plugin.sh
bash tests/shell-lint/test-lint-shell.sh
git diff --check upstream/dev...HEAD
```

Expected: every command exits `0`, the routing eval reports 50 valid decisions
across five fresh-context calls, and the working tree contains only the
intended Task 4 changes.

- [ ] **Step 5: Commit documentation and packaging checks**

```bash
git add README.md docs/superpowers/codex-ai-roles.md \
  tests/codex/test-package-codex-plugin.sh
git commit -m "docs: explain Codex AI role setup"
```

- [ ] **Step 6: Re-run verification from the committed tree**

Run:

```bash
git status --short
python3 tests/codex/test-ai-roles.py
bash tests/codex/test-codex-variant-installer.sh
bash tests/codex/test-marketplace-manifest.sh
bash tests/codex/test-package-codex-plugin.sh
git diff --check upstream/dev...HEAD
```

Expected: `git status --short` prints nothing and all checks exit `0`.

- [ ] **Step 7: Gate the optional live installation smoke test**

Inspect without mutation:

```bash
codex plugin list --json
codex plugin marketplace list --json
```

If `superpowers@openai-curated` is installed, stop and ask the user for
immediate approval before removing it. If approval is declined, record that
the isolated installer and routing tests passed and skip the live smoke test.

Only after approval, run:

```bash
codex plugin remove superpowers@openai-curated --json
scripts/install-codex-variant.sh
```

Start a clean Codex session, verify that the nine `superpowers-*` roles are
available, dispatch one read-only `superpowers-explorer` smoke task, and
confirm its fixed model is `gpt-5.6-luna` with `low` reasoning. Do not run
the live replacement command during implementation without the fresh approval
required by the design.
