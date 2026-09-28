# Personal skill routing

This policy applies when a personal skill is explicitly requested or a Superpowers
phase checkpoint calls for specialist guidance. The personal skills are installed
separately; this file does not make any of them available.

## Selection

1. Select a skill for its **specific method or output**, not a broad topic match.
   For example, a UI task does not automatically require a design brief, flow
   diagram, token file, and browser test.
2. Use the active harness's native skill inventory or discovery mechanism. Read
   the selected skill and check that it is readable before claiming to use it.
   Also check any command or specialized subskill required for the requested work.
3. If an automatically selected skill is unavailable, silently continue the
   Superpowers workflow. If the human explicitly requested it, state plainly
   whether the skill, its file, required command, or subskill is unavailable.
   Ask for a usable installation or location only when that is needed to proceed.
4. Superpowers' approval gates and question pacing take precedence when a
   personal skill would create a file too early or start a second interview.
   Follow an explicit user instruction that changes a Superpowers default, as
   required by `using-superpowers`' User Instructions rule.

A readable `ogt-docs-rules` root skill may still guide work when a specialized
subskill is absent. State the missing subskill if it limits the requested work;
never claim to have used it.

## Phase map

| Skill | Select when | Checkpoint and use |
| --- | --- | --- |
| `create-prd` | Users, outcomes, product requirements, or release scope need definition | Brainstorming: structure product requirements for the architectural design. |
| `design-brief` | A UI feature needs an experience or visual direction | Brainstorming: define experience direction after intent is clear. |
| `user-flow-diagram` | Screen paths, decisions, branches, or recovery paths matter | Brainstorming: map the interaction flow for design review. |
| `trd` | Architecture, API, data, deployment, performance, or security requirements need technical specification | Technical design within brainstorming, before approval of the Superpowers spec. |
| `database-schema-documentation` | Proposed data models or an existing schema need explicit documentation | Technical design for proposed models; execution or verification for the completed schema. |
| `skillui` | The task calls for design-system extraction from a site, codebase, or public repository | Early execution after plan approval, before visual implementation that uses the extraction. Check its command before relying on it. |
| `design-tokens` | A UI needs a token system or token changes | Early execution after approved visual direction and an applicable brief, before components use the tokens. |
| `ogt-docs-rules` | Existing enforceable project rules must be understood, or rules must be created or updated | Read rules during exploration; create or update them as planned execution work. Check the needed specialized subskill. |
| `playwright-cli` | Browser inspection or browser-level verification is needed | Read-only inspection during exploration; interactive browser testing during execution and verification. |

An explicit mention triggers discovery and reading **now**, even when the skill's
usual checkpoint is later. Use its guidance at the current stage; defer writing
files and other implementation actions to the applicable Superpowers stage.

## Stage boundaries

By default, produce **one reviewed Superpowers architectural spec** informed by
relevant PRD, brief, flow, TRD, or schema methods. Matching multiple skills does
not require duplicate documents or separate interviews. When the human asks for
a separate PRD, brief, diagram, TRD, or schema document, preserve that artifact's
content requirements and schedule its creation at a stage allowed by the
Superpowers gates.

Create design tokens after visual direction approval and before dependent
components. Run `skillui` extraction or installation that writes files only
during approved execution. Read existing rules before approval if useful;
authoring rules is execution work. Browser observation may precede approval;
state-changing browser actions and implementation tests follow approval.
