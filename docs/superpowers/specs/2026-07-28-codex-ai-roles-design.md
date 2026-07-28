# Codex AI Roles for Superpowers — Design Spec

**Status:** Approved design; implementation not started
**Branch:** `feat/codex-ai-roles`, based on local `upstream/dev` at
`7b4dc4d`
**Audience:** Personal Codex variant of Superpowers
**Objective:** Map the Superpowers workflow lifecycle to explicit Codex AI
roles, using GPT-5.6 and Kimi K3 according to the kind of work and judgment
required.

## Constraints

- Preserve the existing Superpowers lifecycle and its human approval gates.
- Use Codex-native roles only where Codex actually dispatches a subagent.
- Give primary-thread phases documented model recommendations because native
  roles cannot change the model of the already-running parent agent.
- Use GPT-5.6 Sol selectively for architecture and final judgment, not as a
  universal default.
- No GPT-5.6 role may exceed `high` reasoning.
- Kimi K3 may use `max` reasoning and is the only model allowed to do so.
- `superpowers-implementer` specifically uses GPT-5.6 Terra at `high`.
- Installation must be reversible, idempotent, and must not overwrite or
  silently remove an existing Superpowers installation.
- Before any live verification that requires uninstalling the currently
  installed Superpowers plugin, Codex must ask the user for approval at that
  moment.

## Goals

1. Describe the full Superpowers lifecycle, including its Designer phase.
2. Provide a deliberate model and reasoning recommendation for every
   lifecycle phase.
3. Define native roles for every recurring subagent boundary.
4. Teach dispatching skills how to choose those roles without changing the
   underlying workflow.
5. Provide a managed-link installer for using this checkout as a personal
   Codex variant.
6. Test configuration validity, routing behavior, and safe installation.

## Non-goals

- Changing Superpowers into a Codex-only project.
- Adding native roles for phases that remain in the primary thread.
- Replacing the existing design, planning, review, verification, or human
  approval gates.
- Automatically selecting the user's parent-session model.
- Automatically uninstalling an official or differently sourced Superpowers
  plugin.
- Claiming compatibility with Codex versions older than the version validated
  by this work.
- Upstreaming the personal model preferences as universal defaults.

## Lifecycle Model

The lifecycle is:

```text
Designer → Planner → Controller → Implementer → Task Reviewer
                                      ↑              ↓
                                      └── fix / re-review
                              → Final Reviewer → Branch Finisher
```

The **Designer** is a real lifecycle phase: it is the primary agent running
`brainstorming`. It resolves intent, constraints, alternatives, and the
approved design before implementation planning. It is not a native subagent
role because Codex roles are applied when spawning subagents, not retroactively
to the primary session.

The **Planner** is the primary agent running `writing-plans`. The
**Controller** is the primary agent coordinating plan execution, preserving
cross-task context, adjudicating review findings, and recognizing escalation
conditions. Implementers and reviewers are fresh subagents selected at the
actual dispatch boundary. The Branch Finisher returns to the primary thread
for integration choices and user confirmation.

This produces two complementary layers:

1. **Primary lifecycle recommendations** tell the user which model to choose
   when starting a session for a phase.
2. **Native subagent roles** enforce model and reasoning settings on spawned
   agents.

## Primary-Thread Recommendations

These are documented recommendations, not automatically enforced settings.

| Lifecycle phase | Superpowers workflow | Model | Reasoning | Rationale |
|---|---|---:|---:|---|
| Designer | `brainstorming` | GPT-5.6 Sol | `high` | Architecture, ambiguity resolution, and trade-off judgment |
| Planner | `writing-plans` | GPT-5.6 Sol | `high` | Task boundaries, interfaces, and complete execution instructions |
| Controller | `subagent-driven-development` or `executing-plans` coordination | GPT-5.6 Sol | `high` | Cross-task judgment, review adjudication, and escalation |
| Inline executor | `executing-plans` implementation and `test-driven-development` | GPT-5.6 Terra | `medium` | Balanced implementation when work stays in the parent session |
| Systematic debugger | `systematic-debugging` | GPT-5.6 Sol | `high` | Competing hypotheses and root-cause judgment |
| Review-feedback evaluator | `receiving-code-review` | GPT-5.6 Terra | `high` | Technical scrutiny without requiring the flagship model |
| Workspace and completion operator | `using-git-worktrees`, `verification-before-completion`, `finishing-a-development-branch` | GPT-5.6 Luna | `medium` | Procedural work with explicit checks and bounded choices |
| Skill author | `writing-skills` | GPT-5.6 Sol | `high` | Instruction design and behavioral evaluation |

The recommendation is intentionally not “always high.” Luna uses lower effort
for constrained mechanics, Terra uses medium for ordinary inline
implementation, Terra uses high where review or integration needs more
deliberation, and Sol high is reserved for architecture or high-blast-radius
judgment.

## Native Subagent Roles

Role files live under `agents/` in the source tree and are discovered through
a managed link from the Codex agents directory.

The canonical Codex model identifiers are:

| Display name | Configuration value |
|---|---|
| GPT-5.6 Sol | `gpt-5.6-sol` |
| GPT-5.6 Terra | `gpt-5.6-terra` |
| GPT-5.6 Luna | `gpt-5.6-luna` |
| Kimi K3 | `kimi-oauth/k3` |

| Native role | Model | Reasoning | Dispatch purpose |
|---|---:|---:|---|
| `superpowers-explorer` | GPT-5.6 Luna | `low` | Narrow codebase lookup with a crisp question |
| `superpowers-investigator` | Kimi K3 | `max` | Independent root-cause investigation and broad evidence gathering |
| `superpowers-implementer-mechanical` | GPT-5.6 Luna | `medium` | Complete, low-ambiguity work normally confined to one or two files |
| `superpowers-implementer` | GPT-5.6 Terra | `high` | Normal multi-file implementation and integration |
| `superpowers-implementer-complex` | GPT-5.6 Sol | `high` | Architectural, broad, or unusually ambiguous implementation |
| `superpowers-task-reviewer` | GPT-5.6 Terra | `high` | Fresh per-task correctness and quality judgment |
| `superpowers-re-reviewer` | GPT-5.6 Terra | `medium` | Scoped verification that a known finding was fixed without regression |
| `superpowers-recovery` | Kimi K3 | `max` | Fresh-perspective recovery after repeated failed fix rounds |
| `superpowers-final-reviewer` | GPT-5.6 Sol | `high` | Plan-wide final review and release-level judgment |

Each TOML role will declare:

- a unique `name`;
- a dispatch-oriented `description`;
- `model`;
- `model_reasoning_effort`;
- focused `developer_instructions`; and
- optional `nickname_candidates`.

Role instructions define the agent's operating contract, evidence expected in
its return, and boundaries. They do not duplicate entire skill bodies or
silently relax Superpowers gates.

## Dispatch Routing

The controller chooses roles based on task characteristics:

1. A narrow lookup or repository orientation question uses
   `superpowers-explorer`.
2. Root-cause analysis, multiple plausible hypotheses, or a useful independent
   perspective uses `superpowers-investigator`.
3. A complete, low-ambiguity task normally touching no more than one or two
   files uses `superpowers-implementer-mechanical`.
4. Ordinary multi-file implementation or integration uses
   `superpowers-implementer`.
5. Architectural changes, broad cross-cutting changes, or materially ambiguous
   implementation uses `superpowers-implementer-complex`.
6. The first full review of an implementation task uses
   `superpowers-task-reviewer`.
7. A review limited to verifying a known fix and its regression surface uses
   `superpowers-re-reviewer`.
8. Fix rounds 1–3 resume or redispatch the original implementation role with
   the accumulated finding context.
9. Fix round 4 starts a fresh `superpowers-recovery` agent. It does not inherit
   the original implementer's assumptions.
10. Plan-wide final review uses `superpowers-final-reviewer`.
11. A final-review fix wave that needs a fresh diagnosis uses
    `superpowers-recovery`; final acceptance remains with
    `superpowers-final-reviewer`.

Plan recommendations may suggest a tier, but the controller retains override
authority based on the actual scope and ambiguity at dispatch time.

The routing guidance is integrated only at real dispatch points, primarily:

- `subagent-driven-development`;
- `dispatching-parallel-agents`; and
- `requesting-code-review`.

Other skills remain platform-neutral and refer to the Codex role guide when
they recommend a parent-session model or an optional delegated investigation.

## Failure and Fallback Behavior

Selecting a native role satisfies Superpowers' requirement that subagent model
selection be explicit.

If a configured role, model, or reasoning level is unavailable, the workflow
must stop that dispatch and report:

- the requested role;
- its configured model and reasoning effort;
- what Codex reported as unavailable; and
- the corrective action or an explicit user-selected alternative.

There is no silent fallback to the parent model, a cheaper model, or a lower
reasoning level. This prevents an expensive parent session from being inherited
accidentally and prevents judgment work from silently moving to a weaker tier.

## Codex Integration

Codex plugins package skills, hooks, apps, and MCP configuration, but the
current plugin installation path does not register native agent roles.
Therefore this variant uses both:

1. the normal local Superpowers plugin installation; and
2. a managed symlink under `~/.codex/agents/superpowers` pointing to this
   checkout's `agents/` directory.

The implementation adds:

- `agents/*.toml` for the nine native roles;
- `scripts/install-codex-variant.sh`;
- `scripts/uninstall-codex-variant.sh`;
- a Codex role guide containing the lifecycle and routing matrix;
- minimal changes at relevant subagent dispatch instructions; and
- tests for role schemas, routing, and installer behavior.

### Installer behavior

The installer will:

1. identify the source checkout without relying on the caller's working
   directory;
2. verify the supported Codex version and required model identifiers;
3. inspect current marketplaces, plugin installations, and the target agents
   path;
4. stop with a diagnostic if an official or differently owned Superpowers
   installation is present;
5. register this checkout as the `superpowers-dev` marketplace when safe;
6. install `superpowers@superpowers-dev`;
7. create the managed agents symlink only if the target is absent or already
   points to this checkout; and
8. report that a new Codex session is required.

Running the installer again against the same checkout is a no-op or repairs
only state it owns. It never overwrites a file, directory, or symlink owned by
another installation.

If the currently installed official plugin must be removed for live
verification, the development session asks the user immediately before
removal. The installer itself reports the conflict and exits; it does not make
that authorization decision.

### Uninstaller behavior

The uninstaller removes only:

- the agents symlink when it resolves to this checkout's `agents/` directory;
- the exact `superpowers@superpowers-dev` installation created for the
  variant; and
- the exact local marketplace registration created for the variant when it is
  no longer needed.

If ownership cannot be proven, it exits without removing the target and tells
the user how to inspect the conflict. It does not restore or install the
official plugin automatically.

## Packaging Boundary

The standard Superpowers plugin artifact remains valid for its existing
contents. Native role files and installer scripts are source-checkout
integration assets and must not be assumed to travel through the current
plugin package command unless that packaging boundary is deliberately changed
and tested.

The role guide must state this distinction so users do not expect a packaged
plugin installation by itself to activate AI roles.

## Testing Strategy

### Static role validation

Tests parse every role TOML and verify:

- every role has a unique name, description, and developer instruction;
- every configured model is in the approved GPT-5.6 or Kimi K3 allowlist;
- GPT-5.6 reasoning never exceeds `high`;
- only Kimi K3 uses `max`;
- `superpowers-implementer` is exactly GPT-5.6 Terra at `high`;
- role filenames, declared names, the role guide, and dispatch mapping agree;
  and
- every dispatch role referenced by a skill exists.

### Installer tests

Tests run against temporary configuration paths and a fake Codex executable.
They cover:

- a fresh installation;
- a repeated idempotent installation;
- refusal to overwrite a pre-existing target;
- detection of an official Superpowers installation;
- ownership-checked uninstall;
- missing model support;
- an unsupported Codex version; and
- proof that no conflict path automatically removes another installation.

### Behavioral routing tests

Scenarios verify that:

- a narrow lookup selects `superpowers-explorer`;
- a root-cause investigation selects `superpowers-investigator`;
- bounded mechanical implementation selects the Luna role;
- normal multi-file implementation selects Terra at `high`;
- architectural implementation selects Sol at `high`;
- initial task review and scoped re-review use their distinct roles;
- fix rounds 1–3 retain the original implementation tier;
- fix round 4 and fresh final-fix diagnosis use Kimi K3 at `max`;
- plan-wide final review uses Sol at `high`; and
- a missing role produces an explicit stop instead of silent fallback.

Because this changes skill instructions, evaluation follows the
`writing-skills` test discipline during implementation: capture relevant
baseline behavior first, then run the same Codex/subagent-driven-development
scenarios after the change.

### Compatibility and live verification

The minimum supported Codex version is initially the version used to validate
the implementation: `0.145.0`. The work will not claim earlier-version
compatibility without running the same tests there.

An isolated test environment can validate parsing, routing, and installer
safety without touching the user's active plugin. Final live verification may
require replacing the current official Superpowers installation. That smoke
test is separate from implementation acceptance and runs only with fresh,
explicit user approval immediately before replacement.

## Acceptance Criteria

The feature is ready when:

1. all nine native roles load in a new Codex session with their specified
   models and reasoning levels;
2. primary-thread recommendations cover every Superpowers lifecycle phase,
   including Designer;
3. all actual subagent dispatch boundaries name a valid role and follow the
   routing rules;
4. GPT-5.6 never exceeds `high`, Kimi K3 is the only model at `max`, and the
   Terra implementer remains at `high`;
5. unavailable roles fail explicitly without fallback;
6. installation and uninstallation are idempotent and ownership-safe;
7. the active official plugin is never removed without the user's immediate
   approval;
8. static, installer, and behavioral tests pass; and
9. an isolated Codex configuration demonstrates the expected role selection
   during a representative Superpowers workflow.

If the user authorizes replacement of the active plugin, repeat criterion 9 in
a clean live Codex session as an additional smoke test.
