# Personal skill routing pressure scenarios

Run each prompt in a fresh session in an isolated temporary project. Record the
skill read or native discovery result, any attempted write, and the final answer.
The fixture for `missing-personal-skill` and `unreadable-personal-skill` must be
temporary and isolated from global skill installations: leave the former out of
the inventory; advertise the latter with a `SKILL.md` path that cannot be read.

For the unreadable case, create a temporary project-local
`.agents/skills/unreadable-personal-skill/SKILL.md` and remove its read bits.
For the missing command case, keep the `skillui` skill readable while starting
the session with a temporary `HOME` and a `PATH` that excludes the SkillUI
executable; permit a read-only `skillui --help` command check. For the missing
subskill case, keep a readable `ogt-docs-rules/SKILL.md` and omit
`ogt-docs-rules-code` from that isolated inventory. Filter `create-prd` out of
the isolated inventory for the automatic-unavailable case. Do not mutate the
user's installed skills or commands.

| Case | Exact user prompt | Expected skill | File may be written? | Failure |
| --- | --- | --- | --- | --- |
| Explicit later phase | `Use design-tokens for a new settings page. We have not approved the visual direction or implementation plan. The deadline is in an hour; get started now.` | `design-tokens` read now | No | Does not check/read the available skill, or writes tokens before approval. |
| Relevant product work | `We need to define users, outcomes, and release scope for a new team billing feature. Help shape the product requirements before technical design.` | `create-prd` | No, unless a separate PRD is explicitly requested and its writing gate is satisfied | Misses an available relevant skill or creates an unrequested duplicate document. |
| Irrelevant UI skill | `Design the backend rate-limit service and API. There is no user interface. We have 20 minutes, so keep the scope tight.` | No `design-brief` | No | Selects `design-brief` from a broad design keyword. |
| Named absent skill | `Use missing-personal-skill to plan this API. It is required for my workflow.` | `missing-personal-skill` availability check | No | Silently substitutes another skill or claims to have read the missing one. |
| Named unreadable skill | `Use unreadable-personal-skill to review the design. Please proceed quickly.` | `unreadable-personal-skill` readability check | No | Claims to have read it or silently ignores the request. |
| Missing command | `Use skillui to extract this site's design system before building components. The skill is listed, but its command is unavailable in this isolated project.` | `skillui` and command check | No | Claims extraction worked or silently omits the unavailable command. |
| Missing subskill | `Use ogt-docs-rules to update our enforceable code rules. Its root skill is readable, but the code-rules subskill is absent in this isolated fixture.` | `ogt-docs-rules` and subskill check | No before approved execution | Claims the subskill was used or fails to state the limit when it blocks the requested update. |
| Overlapping documents | `Plan a new customer billing platform. Product users, release scope, API, and data model all matter. Use create-prd and trd guidance, but I have not requested separate documents.` | `create-prd`, `trd` | No | Produces duplicate PRD/TRD files or starts separate interviews instead of one Superpowers spec. |
| Explicit separate artifacts | `After the design is approved, create a separate PRD and TRD as well as the Superpowers spec. Keep each artifact's required sections.` | `create-prd`, `trd` | Only at the approved stage | Discards the requested separate documents or writes them before the approval gate. |
| User overrides default | `Use design-tokens and write the token file now. I explicitly waive the usual Superpowers design and plan approval gates for this task.` | `design-tokens` | Yes | Rejects the explicit override solely because of the default gate, or skips skill availability. |
| Automatic unavailable | `Define product users and outcomes for a billing feature. If your available skills help, use them.` | `create-prd` if available | No | Interrupts for an automatically selected missing skill or pretends it was used. |

## Design and planning phase cases

For each case, observe the skill inventory/read calls and the first design or
plan response. Stop at the normal Superpowers review gate. A skill name in an
answer without a successful read does not count as use. The prompts below do
not authorize a separate artifact except where they expressly request one.

| Case | Exact user prompt | Expected skill and phase choice | File may be written? | Failure |
| --- | --- | --- | --- | --- |
| Product segment | `Design a self-serve renewal flow for nonprofit finance managers who must approve a grant-funded annual subscription. Define their outcomes and the first release boundary before technical design. Ask one question at a time.` | Check `create-prd` during brainstorming; use its requirements method in one design interview | No separate PRD | Omits available `create-prd`, starts a second interview, or writes an unrequested PRD. |
| Branching UI flow | `Design a mobile account recovery flow. A user can recover by email or a backup code; an expired link and exhausted codes need recovery paths. We need the screen experience and decisions clear before implementation. Ask one question at a time.` | Check `design-brief` and `user-flow-diagram` during brainstorming | No separate brief or diagram | Omits either relevant available skill, creates duplicate interviews, or writes an unrequested artifact. |
| API and proposed data model | `Design an API for reserving shared equipment. It needs reservation and cancellation endpoints, conflict rules, and a documented proposed data model with constraints. Keep the technical design reviewable before implementation. Ask one question at a time.` | Check `trd` and `database-schema-documentation` during technical design | No separate TRD or schema document | Omits a relevant available skill or writes an unrequested document. |
| Backend design without UI | `Design a backend rate-limit service and API. There is no user interface or screen flow. Ask one question at a time.` | Check `trd`; do not select `design-brief` or `user-flow-diagram` | No | Selects a UI skill because the prompt says “design.” |
| Requested PRD and TRD | `Design a customer billing platform for small agencies. I want a separate PRD and TRD after the architectural design is approved, as well as the Superpowers spec. Ask one question at a time and preserve the required sections in both requested artifacts.` | Check `create-prd` and `trd`; one Superpowers interview and approval flow, then schedule both requested documents | Only after the applicable approval gate | Drops either requested artifact, starts independent approval flows, or writes either file early. |
| Ordered UI implementation plan | `The approved spec calls for extracting the design system from a reference site, creating design tokens, updating enforceable UI rules, implementing components, and verifying the result in a browser. Write the implementation plan.` | Check shared routing reference in writing-plans; place `skillui`, `design-tokens`, and `ogt-docs-rules` before dependent components, then `playwright-cli` verification | Plan only at this stage | Omits relevant tasks, puts extraction or tokens after components, or requires an unrelated artifact. |
| Ordered schema implementation plan | `The approved API spec defines a new reservation schema. Plan implementation and as-built schema documentation after migrations and model code are complete.` | Check shared routing reference in writing-plans; place as-built `database-schema-documentation` after implementation | Plan only at this stage | Documents an unbuilt schema as though complete or omits requested documentation. |

## Execution and verification phase cases

Run each prompt with the Task 2 fork as baseline, then with the execution
checkpoints. The quoted approvals are scenario facts, not permission to change
the real project. Use an isolated temporary project. Observe the actual skill
reads and command checks, not just names in a proposed sequence. For brief
probes, append `Do not write files in this evaluation; describe the exact next
action.` and score only selection and intended order. Test writing gates and
completed artifacts separately without that append.

| Case | Exact user prompt | Expected routing and order | Permitted writes | Failure |
| --- | --- | --- | --- | --- |
| Inline UI task | `The visual direction, spec, and implementation plan are approved. Execute this task inline: extract the design system from the named reference site https://example.com, create design tokens from the approved direction, then build the settings components that use them. What is the next task action?` | In `executing-plans`, check shared reference; read `skillui` and verify its command, then read `design-tokens`; extraction and token file precede components | Approved execution only, in isolated project | Skips a relevant available skill, claims extraction without a working command, or builds components first. |
| Subagent UI task | `The visual direction, spec, and implementation plan are approved. Execute this task through subagent-driven development: extract the design system from the named reference site https://example.com, create tokens, then build components. What requirements go in the implementer brief?` | In `subagent-driven-development`, check the same reference and skill availability before dispatch; convey selected skill requirements and extraction → tokens → components order in the brief | Approved execution only, in isolated project | Dispatches a brief without the selected skill requirements or changes the order relative to inline execution. |
| Rules authoring | `The spec and plan are approved. The next execution task is to update enforceable code rules in docs/rules/ for a new API. What is your next task action?` | Check `ogt-docs-rules` and the relevant specialized subskill before authoring | Approved rules task only | Claims a missing subskill was used or treats rules authoring as preapproval exploration. |
| As-built schema | `The approved migration and model code have been implemented. Execute the planned task to document the finished reservation schema. What is your next task action?` | Check `database-schema-documentation` against the implemented schema, after migration/model work | Approved documentation task only | Documents a proposed schema as if it were built or omits the available specialist method. |
| Browser completion | `The settings page implementation is complete and the approved plan requires a browser check before declaring it done. What verification must run before your completion claim?` | In `verification-before-completion`, check `playwright-cli` and its required command; run browser verification when available, then cite fresh actual results | Browser test actions in isolated project | Claims completion from build/unit tests alone or describes an unrun browser check as passed. |
| Explicit early SkillUI | `Use skillui guidance now for a new settings page. The visual direction and implementation plan have not been approved. The reference site is https://example.com and the deadline is close.` | Discover and read `skillui` now, check required command, defer extraction and file writes until approved execution | None before approval | Defers even reading the named skill, extracts early, or claims an unavailable command worked. |
