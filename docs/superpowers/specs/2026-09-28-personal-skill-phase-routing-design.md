# Personal Skill Phase Routing for the Superpowers Fork

**Date:** 2026-09-28  
**Status:** Design approved in conversation; implementation pending written-spec review  
**Scope:** This private Superpowers fork, Codex CLI, Codex desktop, and Oh My Pi (OMP)

## Purpose

Make this fork of Superpowers select nine separately installed personal skills at the right points in its workflow. The agent checks whether a skill is available before using it, uses an available skill when its specific method or output is relevant, and honors an explicit request for a skill. The same behavior must run from this fork in Codex CLI, Codex desktop, and OMP. This is a private divergence from upstream, not a proposed upstream contribution.

## Existing Behavior and Constraints

- Superpowers owns the development lifecycle: brainstorming, design review, a written spec, implementation planning, execution, verification, and finishing. Its approval gates remain in force.
- Codex packages the repository's `skills/` directory through `.codex-plugin/plugin.json`. The Codex manifest intentionally has no hook. Codex CLI and desktop must therefore receive the routing instructions through the packaged skills.
- OMP loads this repository as a Pi package when linked or installed. Its extension injects `using-superpowers` at session start and after compaction, and exposes the same `skills/` directory.
- The nine personal skills are installed outside this repository. Do not copy them into Superpowers, add them as dependencies, or hardcode this machine's home directory. Discover what the active harness exposes at run time.
- The current Codex desktop task uses upstream Superpowers. OMP currently uses an installed package rather than this checkout. Changing files here does not by itself activate the fork in either installation.

## Routing Architecture

Use **phase checkpoints**, with a single shared routing reference that defines the nine skills, their relevance tests, phase placement, and conflict rules. Keep a short discovery rule in `using-superpowers` so an explicit skill mention is recognized before other work. Add concise checkpoint instructions to the existing Superpowers skills that own brainstorming, planning or execution, and verification. Those checkpoint instructions refer to the shared routing reference rather than duplicating its table.

At a checkpoint, the agent:

1. Determines which personal skills are relevant to the current task and phase using the skill descriptions and the routing table below. A broad topic match alone is insufficient: a UI task does not automatically need every UI artifact.
2. Checks the active harness's skill inventory or native discovery mechanism. It reads and applies the installed skill only if the skill is actually available. It does not claim to have invoked a skill merely because its name appears in this spec.
3. If the skill was selected automatically but is unavailable, continues the Superpowers workflow without interruption. If the human explicitly requested it and it is unavailable, states that plainly and asks for a usable installation or location only when needed to proceed.
4. Applies Superpowers' process gates and question pacing when the selected skill's instructions would otherwise start a second interview, create an artifact too early, or skip a required review. The personal skill supplies its specialist method and content.

An explicit mention triggers the availability check promptly, even when the named skill usually belongs to a later phase. Reading the skill and using its guidance may begin immediately; file creation and other implementation actions wait for the applicable Superpowers design and plan approvals. A user instruction that explicitly changes a process gate still takes precedence under the existing Superpowers instruction hierarchy.

## Phase Map

| Skill | Relevant condition | Checkpoint and use |
| --- | --- | --- |
| `create-prd` | Product requirements, users, outcomes, or release scope need definition | Brainstorming: structure product requirements and feed the architectural design. |
| `design-brief` | A UI feature needs an experience or visual direction | Brainstorming: define the experience direction after intent is clear. |
| `user-flow-diagram` | Screen paths, decisions, branches, or recovery paths matter | Brainstorming: map the interaction flow for design review. |
| `trd` | Architecture, API, data, deployment, performance, or security requirements need technical specification | Technical design within brainstorming, before the Superpowers spec is approved. |
| `database-schema-documentation` | Data models or an existing schema need explicit documentation | Technical design for proposed data models; execution or verification for documentation of the completed schema. |
| `skillui` | The task calls for extracting a design system from a site, codebase, or public repository | Early execution after plan approval, before visual implementation that uses the extracted system. |
| `design-tokens` | A UI needs a token system or token changes | Early execution after design approval and an applicable brief or direction, before building components that consume the tokens. |
| `ogt-docs-rules` | Existing enforceable project rules must be understood, or rules must be created or updated | Read existing rules during project exploration. Create or update rules as a planned execution task. |
| `playwright-cli` | Browser inspection or browser-level verification is needed | Read-only inspection during exploration when appropriate; interactive browser testing during execution and verification. |

## Documents and Stage Boundaries

The default is one reviewed Superpowers architectural spec, informed by any relevant PRD, brief, flow, TRD, or schema method. Do not require duplicate documents merely because multiple skills match. Produce a separate PRD, brief, diagram, TRD, or schema document when the human asks for that artifact; schedule its file creation at a stage permitted by Superpowers' approval gates. Preserve an explicitly requested artifact's own content requirements.

`design-tokens` follows an approved visual direction and precedes components. `skillui` extraction or installation that writes files happens only during approved execution. `ogt-docs-rules` may guide context gathering by reading rules before design approval, while authoring rules is execution work. Browser inspection before approval must be limited to observation; browser actions that change application state or serve as implementation tests belong after approval.

## Active Installation and Rollout

Both Codex surfaces and OMP must load this fork, not their currently installed upstream copies:

1. Make this repository's `.agents/plugins/marketplace.json` a valid local marketplace entry for the fork. Keep one canonical plugin identity, `superpowers`, disambiguated by the local marketplace name `superpowers-dev`.
2. Register and install `superpowers@superpowers-dev` for Codex. Disable or remove the upstream Superpowers installation so its skills do not compete with the fork. Confirm Codex CLI resolves the local plugin. Restart Codex desktop and verify in a fresh task that its Superpowers skill content comes from the fork. The current task's already loaded skill context is not proof of the switch.
3. Link or install this checkout in OMP in place of its existing installed Superpowers package. Confirm OMP's plugin inventory resolves to this checkout and that a fresh OMP session receives the fork's bootstrap.
4. Document the repeatable refresh procedure. Local Codex plugins are loaded from an installed cache, so later edits to this checkout require a refresh and a new desktop session. The official packaging guidance describes local marketplaces, the installed cache, and desktop restart: <https://developers.openai.com/plugins/build/plugins>.

Do not modify the Codex marketplace cache or OMP package files directly. Use supported plugin installation mechanisms so the fork remains maintainable.

## Verification

Develop the skill changes with the repository's `writing-skills` method: record baseline behavior, add pressure scenarios, observe failures, make the smallest instruction changes that address them, and re-run the scenarios. Include scenarios for:

- Automatic selection of an available, relevant skill at each phase class.
- A named skill that is normally associated with a later phase: acknowledge and load it now while preserving file-writing gates.
- Automatically relevant but unavailable skill: continue without falsely claiming use.
- Explicitly requested but unavailable skill: report unavailability clearly.
- Multiple matching document skills: preserve one Superpowers spec by default and create a separate artifact only when requested.
- A UI execution plan: `skillui` and `design-tokens` precede dependent components, and `playwright-cli` verifies browser behavior.
- A fresh session after compaction in OMP: the routing policy remains present without duplicate bootstrap messages.

Run applicable structural and packaging tests in the repository. Run behavioral checks in fresh Codex CLI and OMP sessions against the fork, and a fresh Codex desktop task after switching its installation. Capture the observed skill invocation and approval sequence. Passing static tests alone does not establish behavioral routing.

## Success Criteria

- Each of the nine skills has one documented relevance rule and checkpoint, and no task invokes an unavailable skill as though it were installed.
- An explicit mention results in an immediate availability check and appropriate use, without silently bypassing Superpowers approvals.
- Automatically relevant skills are used when available, without generating unrelated artifacts or duplicate interviews.
- Codex CLI, Codex desktop, and OMP each load this fork and pass the applicable fresh-session behavior checks.
- The fork introduces no dependency on the nine external skills and contains no copies of them.
- No upstream PR is opened for this private customization.
