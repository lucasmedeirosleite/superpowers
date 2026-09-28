# Personal Skill Phase Routing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make this private Superpowers fork select nine installed personal skills at phase checkpoints and become the active Superpowers plugin in Codex CLI, Codex desktop, and OMP.

**Architecture:** A short bootstrap rule in `using-superpowers` points to one routing reference. Brainstorming, planning, execution, and verification skills contain small checkpoint reminders; the fork keeps the external skills separate. A local Codex marketplace and an OMP package link activate the same checkout in all three surfaces.

**Tech Stack:** Markdown skills, JSON plugin marketplace, shell/Node/Python repository tests, Codex CLI 0.155.0-alpha.16.3, OMP 18.2.6.

**Spec:** `docs/superpowers/specs/2026-09-28-personal-skill-phase-routing-design.md`

## Global Constraints

- This is a private divergence from upstream, not a proposed upstream contribution.
- Superpowers' approval gates remain in force.
- Do not copy the nine personal skills into Superpowers, add them as dependencies, or hardcode this machine's home directory.
- Discover what the active harness exposes at run time.
- Codex CLI, Codex desktop, and OMP must each load this fork and pass fresh-session behavior checks.
- Do not modify the Codex marketplace cache or OMP package files directly. Use supported plugin installation mechanisms.
- Do not require duplicate documents merely because multiple skills match.
- An explicit mention triggers the availability check promptly; file creation and other implementation actions wait for applicable Superpowers approvals.

## Review Focus

These five cases supplement the direct spec scenarios. Each is pinned to a task's behavioral or installation check below.

1. A backend task uses the word “design” without needing a UI brief: Task 2 checks that `design-brief` is not selected.
2. A named skill is unreadable or relies on an unavailable command or subskill: Task 1 checks that the agent reports the limitation rather than claiming full use.
3. A user asks for both a PRD and TRD in a single architectural task: Task 2 checks that the requested artifacts are honored without two independent Superpowers approval flows.
4. A user names `skillui` during brainstorming: Task 3 checks that the agent loads its guidance but does not generate files before the approved execution stage.
5. Upstream and forked Superpowers are simultaneously installed: Task 4 checks that only the fork is enabled before the Codex desktop acceptance run.

---

## File Map

| File | Responsibility |
| --- | --- |
| `skills/using-superpowers/references/personal-skill-routing.md` | One table of nine relevance rules, phase placement, availability, precedence, and document behavior. |
| `skills/using-superpowers/SKILL.md` | Early detection of explicit mentions and a pointer to the shared reference. |
| `skills/brainstorming/SKILL.md`, `skills/writing-plans/SKILL.md` | Design and planning checkpoints. |
| `skills/executing-plans/SKILL.md`, `skills/subagent-driven-development/SKILL.md`, `skills/verification-before-completion/SKILL.md` | Execution and verification checkpoints for both plan execution modes. |
| `tests/personal-skill-routing/scenarios.md` | Reusable pressure prompts and observable pass/fail criteria; no implementation-mirroring assertions. |
| `docs/superpowers/evals/2026-09-28-personal-skill-routing.md` | Before/after observations with harness, version, prompt, actual skill use, and gate behavior. |
| `.agents/plugins/marketplace.json`, `tests/codex/test-marketplace-manifest.sh` | Valid local marketplace source and its regression check. |
| `docs/personal-fork-installation.md` | Repeatable activation and refresh steps for Codex CLI, Codex desktop, and OMP. |

### Task 1: Shared routing policy and explicit-request bootstrap

**Files:** Create `skills/using-superpowers/references/personal-skill-routing.md`, `tests/personal-skill-routing/scenarios.md`, and `docs/superpowers/evals/2026-09-28-personal-skill-routing.md`; modify `skills/using-superpowers/SKILL.md:18-32`.

**Interfaces:** Produces `references/personal-skill-routing.md` with sections `Selection`, `Phase map`, and `Stage boundaries`. Later checkpoints refer to this exact relative path and these rules; no harness-specific path appears in the policy.

- [ ] **Step 1: Write baseline pressure scenarios.** Add exact prompts for explicit `design-tokens` before design approval, relevant `create-prd`, irrelevant `design-brief` in backend design, unavailable named skill, unreadable named skill, missing `skillui` command or `ogt-docs-rules` subskill, and overlapping PRD/TRD. Each scenario records the expected skill name, whether a file may be written, and what would constitute a failure. Create the unavailable and unreadable cases in a temporary isolated skill fixture; do not alter global installations. Include a test case for a user request that explicitly overrides a Superpowers default.
- [ ] **Step 2: Run the baseline before editing skills.** In isolated temporary projects, run the prompts against the current Codex CLI and OMP installations (or isolated subagent sessions that load the current unmodified skills). Record actual excerpts and verdicts in the eval report. Expected: the report distinguishes observed passes from observed failures; do not invent a RED result if a scenario already passes.
- [ ] **Step 3: Write the routing reference.** Include all nine exact skill names from the spec and the four selection rules: specific relevance rather than topic matching; native skill-inventory/readability check plus any required command or subskill check; silent skip for automatically selected unavailable skills and clear notice for explicitly requested unavailable skills; Superpowers approval and question-pacing precedence. Include the default single-spec rule and requested-separate-artifact rule. A readable `ogt-docs-rules` root skill may still be used when one of its specialized subskills is absent, but the agent must state that limit if it affects the requested work.
- [ ] **Step 4: Add the bootstrap pointer.** Add a concise rule under `The Rule` in `using-superpowers`: on an explicit mention or an applicable phase checkpoint, read `references/personal-skill-routing.md`, check availability, and use the relevant skill. Preserve the existing skill-priority and user-instruction rules.
- [ ] **Step 5: Re-run explicit and availability scenarios.** Use the same prompts against a fork-loaded test session. Expected: a named available skill is read, an unavailable or unreadable named skill is reported, a missing command or subskill is reported when it limits the requested work, an automatically unavailable skill is skipped, and no file-writing gate is bypassed unless the user explicitly overrode it. Record before/after excerpts, then run `git diff --check` (expected exit 0) and commit the task's files.

### Task 2: Brainstorming and planning checkpoints

**Files:** Modify `skills/brainstorming/SKILL.md:191-265` and `skills/writing-plans/SKILL.md:21-43`; update the same scenario and eval files from Task 1.

**Interfaces:** Consumes Task 1's `references/personal-skill-routing.md`. Produces design-stage and plan-stage checkpoints; Task 3 relies on plans placing `skillui`, `design-tokens`, rules authoring, schema documentation, and browser verification in the right order.

- [ ] **Step 1: Add design-stage pressure cases.** Include a product feature with a real user segment, a UI flow with branching, an API/data design, and a backend “design” request with no UI. Add the PRD+TRD requested-artifacts case from Review Focus. Expected phase choices are `create-prd`, `design-brief`/`user-flow-diagram`, `trd`/`database-schema-documentation`, and no `design-brief` respectively.
- [ ] **Step 2: Run these cases against the Task 1 fork.** Record whether each relevant skill is checked and whether the agent starts duplicate interviews or writes a separate document without a request. Expected: at least one documented gap before adding the checkpoint; if none fails, document that result and keep the checkpoint wording minimal.
- [ ] **Step 3: Add the brainstorming checkpoint.** After intent is understood and before presenting design sections, consult the shared reference for `create-prd`, `design-brief`, `user-flow-diagram`, `trd`, `database-schema-documentation`, and read-only uses of `ogt-docs-rules` or `playwright-cli`. Keep one-question-at-a-time and the architectural hard gate intact.
- [ ] **Step 4: Add the planning checkpoint.** Before defining implementation tasks, consult the shared reference so plans place `skillui`, `design-tokens`, rule authoring, as-built schema docs, and browser verification before their dependents. Do not require these tasks when the output is irrelevant.
- [ ] **Step 5: Re-run the design cases.** Expected: relevant skills are checked, the backend case omits `design-brief`, requested PRD+TRD outputs are honored within one Superpowers approval flow, and no unrequested duplicate document appears. Record evidence, run `git diff --check` (expected exit 0), and commit the task's files.

### Task 3: Execution and verification checkpoints

**Files:** Modify `skills/executing-plans/SKILL.md:164-207`, `skills/subagent-driven-development/SKILL.md:221-286`, and `skills/verification-before-completion/SKILL.md:22-48`; update the scenario and eval files.

**Interfaces:** Consumes Task 1's routing reference and Task 2's plan placement. Produces equivalent per-task routing behavior in inline and subagent execution, plus browser verification before completion claims.

- [ ] **Step 1: Add execution pressure cases.** Include a UI plan requiring extraction from a named site, a token file before components, a rules-authoring task, documentation of a finished schema, and a browser-tested page. Add the early `skillui` mention from Review Focus. Record expected phase order and allowed file writes.
- [ ] **Step 2: Run these cases against the Task 2 fork.** Record omissions, premature file writes, and differences between inline and subagent paths. Expected: observable baseline results for each path before editing its skill.
- [ ] **Step 3: Add execution checkpoints.** In each execution skill's per-task loop, consult the shared reference before a task that calls for `skillui`, `design-tokens`, `ogt-docs-rules`, or as-built `database-schema-documentation`. Pass selected skill requirements through the task brief in subagent mode. Keep skill selection tied to the task and approved plan.
- [ ] **Step 4: Add the verification checkpoint.** Before claiming browser-facing work complete, check whether `playwright-cli` is relevant and available; use it for browser verification when it is, then apply the existing fresh-evidence rule. Do not turn every code change into a browser test.
- [ ] **Step 5: Re-run execution cases.** Expected: guidance from an early named `skillui` is loaded without creating files until execution; `skillui` and tokens precede dependent components; both execution modes use the same routing table; browser verification cites actual results. Record evidence, run `git diff --check` (expected exit 0), and commit the task's files.

### Task 4: Codex marketplace and active fork

**Files:** Modify `.agents/plugins/marketplace.json:8-12` and `tests/codex/test-marketplace-manifest.sh:36-55`; create `docs/personal-fork-installation.md`.

**Interfaces:** Consumes the completed `skills/` tree. Produces `superpowers@superpowers-dev` as a local Codex marketplace entry with `source: {"source":"local","path":"./"}`; Task 5 uses the installation guide's identity and refresh checks.

- [ ] **Step 1: Make the marketplace test fail.** Change the test's expected source object to `{"source":"local","path":"./"}` and run `bash tests/codex/test-marketplace-manifest.sh`. Expected: failure on the current `url` source.
- [ ] **Step 2: Fix the marketplace entry.** Change only its source object to the local-path form and rerun the test. Expected: `Codex marketplace manifest looks good`.
- [ ] **Step 3: Document installation.** Describe `codex plugin marketplace add "$(git rev-parse --show-toplevel)"`, `codex plugin add superpowers@superpowers-dev`, finding and disabling/removing the exact upstream plugin ID, desktop restart/new-task verification, cache refresh after edits, and rollback to upstream. Explain that the repository's `.codex-plugin/plugin.json` keeps `hooks: {}`.
- [ ] **Step 4: Run package checks and commit.** Run `bash tests/codex/test-package-codex-plugin.sh` and `git diff --check`. Expected: both exit 0; the package includes the modified `skills/` tree and excludes source-only files. Commit the marketplace, test, and guide changes.
- [ ] **Step 5: Activate Codex CLI and desktop.** Using supported plugin commands and the local marketplace, install the fork and remove or disable the exact upstream plugin ID returned by the installed-plugin inventory. Do not edit caches. Check that only the fork is enabled. Restart desktop and use a fresh task to run one explicit-request and one automatic-relevance scenario; verify the installed `using-superpowers` contains the fork's routing pointer. Record results in Task 5's eval report. If a desktop restart or new-task prompt requires the human's action, present the installed state and the exact acceptance prompt as the final required step rather than claiming desktop verification.

### Task 5: OMP activation and cross-harness evidence

**Files:** Update `docs/personal-fork-installation.md` and `docs/superpowers/evals/2026-09-28-personal-skill-routing.md`; modify `.pi/extensions/superpowers.ts` or `tests/pi/test-pi-extension.mjs` only if a demonstrated OMP loading or compaction failure requires it.

**Interfaces:** Consumes the finished `skills/` tree and Task 4's local identity. Produces an OMP plugin inventory pointing at this checkout and a before/after result matrix for Codex CLI, Codex desktop, and OMP.

- [ ] **Step 1: Record OMP's current source.** Run `omp plugin list --json`. Expected before activation: the existing installed Superpowers package, not this checkout.
- [ ] **Step 2: Link this checkout with the supported OMP plugin command.** Use `omp plugin link "$(git rev-parse --show-toplevel)"` under the required filesystem permission and verify `omp plugin list --json` resolves Superpowers to this checkout. Document the reversible command and rollback in the installation guide; do not rely on OMP's `--dry-run` for safety because it attempted a package removal in this environment.
- [ ] **Step 3: Run OMP fresh-session cases.** Use the same automatic, explicit, unavailable, and approval-gate prompts from the scenario file. Record observed skill reads and document output. Run `node --test tests/pi/test-pi-extension.mjs` (expected 0 failures), including the existing post-compaction bootstrap check; extend the test only if actual OMP behavior exposes a missing case.
- [ ] **Step 4: Finish the evidence matrix.** Compare baseline and fork behavior for every scenario, with actual Codex CLI, Codex desktop, and OMP observations. Confirm that all nine names are covered, no external skill was copied into the repo, only the fork is active in each harness, and no upstream PR exists. Run the applicable test suite and `git diff --check` once more; record commands, exit codes, and limits. Commit the evidence and guide changes.
