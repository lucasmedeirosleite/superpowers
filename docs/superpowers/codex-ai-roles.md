# Codex AI Roles

This personal Superpowers variant separates primary-thread model
recommendations from enforceable native subagent roles. Native roles apply
only when Codex spawns a subagent.

## Operating Modes

The dispatching skills apply these modes in this precedence order:

1. **Managed native-role variant active.** The complete Superpowers
   native-role set is exposed — Codex discovers it through the managed
   `~/.codex/agents/superpowers` link created by this checkout's
   `scripts/install-codex-variant.sh`. Every applicable dispatch boundary
   uses the named `superpowers-*` role below.
2. **Variant active but unavailable.** The variant is active, yet Codex
   reports a required role, configured model, or reasoning effort
   unavailable. Stop that dispatch and report the role, configured model
   and effort, availability error, and corrective action or explicit
   user-selected alternative. Never silently inherit the parent model or
   substitute another role.
3. **Standard packaged plugin.** No Superpowers native roles are exposed
   at all — a standard packaged plugin installation contains no role
   definitions. Keep the existing platform-neutral generic dispatch and
   model-tier behavior. This is the non-variant operating mode, not a
   fallback from a failed active role: mode 2's stop rule applies only
   while the variant is active, and a failed role dispatch in mode 1 never
   silently drops into mode 3.

The standard packaged plugin remains fully usable: every Superpowers
workflow works in mode 3 with generic dispatch. Native roles add enforced
model and reasoning selection for the managed variant only.

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

These routing rules bind in mode 1, when the complete Superpowers
native-role set is exposed. In mode 2 (variant active but unavailable),
stop as described above. In mode 3 (no roles exposed at all), dispatch
generically with an explicit model tier instead.

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

## Troubleshooting

| Diagnostic | Resolution |
|---|---|
| Codex 0.145.0 or newer is required | Upgrade Codex, then rerun the installer. |
| `kimi-oauth/k3` is unavailable | Configure the Kimi OAuth model provider so `codex debug models` lists `kimi-oauth/k3`. |
| A model does not support the configured reasoning effort | Update the local model catalog/provider configuration; do not lower or substitute a role silently. |
| `superpowers-dev` belongs to another checkout | Remove that marketplace only after confirming its owner, or use that checkout instead. |
| The agents target is not owned by this checkout | Inspect `~/.codex/agents/superpowers`; move or remove it yourself only after confirming its owner. |
| A role is missing in Codex after install | Confirm the managed link, then start a completely new Codex session because roles are discovered at session start. |
