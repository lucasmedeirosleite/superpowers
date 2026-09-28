# Personal skill routing: Task 1 evaluation

Date: 2026-09-28. Base commit: `52645a6`. Prompts and acceptance criteria are in `tests/personal-skill-routing/scenarios.md`. All project writes were confined to `/tmp/personal-skill-routing-*`.

## Harness provenance and correction

The initial OMP command used `--plugin-dir <checkout>` while the active upstream OMP package remained installed. Its trace resolved `skill://using-superpowers` and `skill://brainstorming` from upstream, and did not read the new reference. The earlier claim that this was fork GREEN evidence was **incorrect**. Those runs are excluded from the fork verdicts below.

For valid OMP A/B runs, I archived base commit `52645a6` to `/tmp/personal-skill-routing-base-repo` and invoked each package with `--no-extensions -e <package>/.pi/extensions/superpowers.ts --plugin-dir <package>` and isolated `PI_PACKAGE_DIR=/tmp/personal-skill-routing-omp-packages-{base,green}`. The explicit extension is the only bootstrap injected for these runs. Both prompts appended “Do not write files in this evaluation; describe the exact next action” to the scenario text, so these runs verify skill loading and reference provenance rather than an unassisted approval-gate decision. The baseline `skill://using-superpowers` read result had no `personal-skill-routing.md` pointer; in the fork run it did, and the trace separately read `skill://using-superpowers/references/personal-skill-routing.md` with `## Selection`. No active OMP installation was changed.

Codex CLI 0.155.0-alpha.16.3 ran from an isolated `CODEX_HOME` with installed personal skills. It did **not** load this fork; its results are baseline/fixture observations only. Fork activation through a local Codex marketplace belongs to Task 4. OMP version was 18.2.6.

## Baseline before the Task 1 edit

| Case | Observed result | Verdict |
| --- | --- | --- |
| Explicit `design-tokens`, isolated base OMP with an added no-write instruction | Read `skill://using-superpowers`, `skill://brainstorming`, and `skill://design-tokens`; wrote no file. Did not read a routing reference because none existed. | Existing behavior **passed** named skill reading; reference absent. The prompt itself required no writing, so this run does not independently prove gate behavior. |
| Exact explicit `design-tokens`, Codex CLI | Read installed `design-tokens/SKILL.md`; final said approval was needed and no files were written. | Pass. |
| Overlapping `create-prd`/`trd`, Codex CLI | Read both installed skills and began “one integrated platform plan.” | Pass for reading and avoiding immediate duplicate files. |
| Missing named skill, original active OMP installation | Reported skill absent and asked for its location. | Pass, but provenance is upstream OMP, not fork. |
| Unreadable named skill, Codex CLI | Found temporary `SKILL.md` with no read bits; reported it could not use that skill. | Pass. |
| Missing `ogt-docs-rules-code`, Codex CLI | Read the root skill and stated the specialized subskill was absent. | Pass. |
| Missing `skillui` CLI, first Codex attempt | Login shell restored the global executable despite a restricted `PATH`; `skillui --help` succeeded. | **Invalid fixture**, excluded. |
| Missing `skillui` CLI, isolated Codex `HOME` | Read the skill; `skillui --help` exited 127, and final reported command unavailable. | Pass. |

The original sandbox blocked Codex model networking and OMP runtime writes. These fresh sessions ran through approved execution. The Codex command fixture used a temporary `HOME` plus `CODEX_HOME` so the login shell could not restore `~/.local/bin/skillui`.

## Fork-loaded OMP results

All rows used the explicit fork extension and JSON trace. The shared reference
was read in each fork-loaded case except the backend-only irrelevant-skill case;
that run selected `trd` without reading the shared reference.

| Scenario | Observed skill/action and final behavior | Verdict |
| --- | --- | --- |
| Explicit `design-tokens` before approval with an added no-write instruction | Read fork bootstrap, shared reference, and `design-tokens`; final: “Reading the requested skill now does not authorize executing its file-writing steps.” No files written. | Pass for fork skill and reference loading. The prompt itself required no writing, so gate behavior remains unproven by this run. |
| Exact relevant `create-prd` | Read `create-prd` and asked one product discovery question; no file written. | Pass. |
| Exact backend design with irrelevant `design-brief` | Read `trd`, not `design-brief`; asked one question about the rate-limit purpose. | Pass. |
| Exact missing named skill | Read attempt returned unavailable; final requested a readable SKILL.md location, without claiming use. | Pass. |
| Unreadable named skill fixture | Read attempt and local path returned `EACCES`; final named the unreadable `SKILL.md` and asked for a readable location. | Pass. |
| `skillui` skill with missing command | Read `skillui`; with temporary `PATH=/usr/bin:/bin`, `skillui --help` exited 127; final reported missing CLI and no extraction. | Pass. First attempt with `always-ask` could not run the check and was excluded; retest used command approval. |
| `ogt-docs-rules` root with absent code subskill | Read root; final used root-level guidance, stated `ogt-docs-rules-code` was absent, and made no false use claim. | Pass. |
| Automatically relevant but filtered-out `create-prd` | Inventory filtered to `using-superpowers,brainstorming`; read attempt returned `Unknown skill: create-prd`; final continued product discovery without interruption or a use claim. | Pass. |
| Overlapping PRD/TRD | Read `create-prd`, `trd`, and schema guidance; asked one context question, creating no duplicate documents. | Pass at this discovery stage; later spec creation was not exercised. |
| Requested separate PRD/TRD | Read both; final planned three separate artifacts with their required sections after design approval. | Pass at planning stage; artifact creation was not exercised. |
| Explicit user waiver of default approvals | Read fork reference and `design-tokens`; wrote `tokens.css` in the isolated temporary project despite default gates. | **Partial:** override honored and file created. Session hit its 120-second deadline during optional validation, so there is no completed final answer or full verification. |

The unreadable fixture was a temporary project-local `.agents/skills/unreadable-personal-skill/SKILL.md` with mode `000`. The missing subskill fixture kept a readable root `ogt-docs-rules/SKILL.md` and omitted `ogt-docs-rules-code`. The absent skill was left out of the inventory. These fixtures did not alter global installations.

## Structural checks and limits

`node tests/pi/test-pi-extension.mjs` passed 6/6. `git diff --check` exited 0. Task 1 does not install the fork into Codex; Codex fork behavior remains a Task 4/5 verification dependency. The valid isolated base OMP run already read the explicitly named skill, so this evaluation does not present a fabricated behavioral RED for that case. The added policy and pointer are demonstrated by the fork-only reference read and the availability results, with the override case remaining partial due to the timeout.

## Task 2: design and planning checkpoints

The exact prompts and acceptance criteria are in the “Design and planning phase
cases” table in `tests/personal-skill-routing/scenarios.md`. Before editing the
two phase skills, I ran all seven prompts in fresh OMP 18.2.6 sessions against
the Task 1 fork at `db4f1c3`. After adding the checkpoints, I repeated all
seven in new sessions against the edited fork. Each run used an isolated `/tmp`
project and `PI_PACKAGE_DIR`, `--no-extensions`, the checkout's explicit
`.pi/extensions/superpowers.ts`, `--plugin-dir` pointing to this checkout,
`--no-session`, JSON trace, and a 90-second limit. This avoids attributing an
active upstream OMP package to the fork. Raw JSON traces are in
`/tmp/personal-skill-routing-task2/logs/{case}-{before,after}.jsonl`.
The run appended “Do not write files in this evaluation; describe the exact
next action” to each exact scenario prompt. Consequently, these checks test
skill selection, one-interview pacing, and intended stage order, but not an
unassisted file-writing gate or completed artifact content.

| Case | Before: observed fork reads and first response | After: observed fork reads and first response | Verdict |
| --- | --- | --- | --- |
| Product segment | Read `create-prd`; asked one question about approval evidence; no extra PRD. | Read `create-prd`; asked one question about grant approval evidence; no extra PRD. | Pass before and after. |
| Branching UI flow | Read `design-brief` and `user-flow-diagram`; asked one fallback-path question; no extra artifact. | Read both; asked one support-recovery question; no extra artifact. | Pass before and after. |
| API and proposed data model | Read `trd` and `database-schema-documentation`; asked one question about reservation units; described one reviewable design. | Read both; asked one allocation-model question; described one reviewable design. | Pass before and after. |
| Backend without UI | Read `trd`, no UI skill; asked one service-purpose question. | Read `trd`, no `design-brief` or `user-flow-diagram`; asked one service-purpose question. | Pass before and after. |
| Requested PRD and TRD | Read `create-prd` and `trd`; planned one interview and three artifacts after design approval. | Read both; explicitly retained one interview, three requested artifacts after design approval, then Superpowers spec review. | Pass before and after. Actual artifact content not exercised. |
| UI plan order | Read `writing-plans`, `skillui`, `design-tokens`, `ogt-docs-rules`, and `playwright-cli`; planned extraction and tokens before components, browser verification after. | Read the same guidance and gave the same dependency order. | Pass before and after. Exact task paths unavailable in empty fixture. |
| As-built schema plan | Read `writing-plans` and `database-schema-documentation`; put documentation after migrations/model code. | Read both; explicitly put as-built documentation after implemented and verified schema. | Pass before and after. |

Every after trace read the fork's `using-superpowers` bootstrap and the shared
`references/personal-skill-routing.md`. The baseline already met these
first-response criteria, so there is **no behavioral RED** to claim. The two
new checkpoints are intentionally short reminders at the owning phases; this
evaluation supports continued behavior and explicit checkpoint placement,
not an improvement measured by these prompts. Codex CLI and desktop fork
activation remain Task 4/5 dependencies.

Task 2 review limit: the UI-plan traces had two blocked command checks and the
`ogt-docs-rules-code-front` subskill was absent. Their intended ordering did not
verify that the extraction, browser, or specialized rules tooling was usable.

## Task 3: execution and verification checkpoints

The six prompts and acceptance criteria are in the “Execution and verification
phase cases” table in `tests/personal-skill-routing/scenarios.md`. I ran each
before and after in fresh OMP 18.2.6 sessions. The before package was an
archive of Task 2 commit `1205961` in `/tmp/personal-skill-routing-task3/base-repo`;
the after package was this worktree. Each call used `--no-extensions`, the
package's explicit `.pi/extensions/superpowers.ts`, `--plugin-dir` for that
package, a distinct `PI_PACKAGE_DIR`, `--no-session`, JSON output, and an
isolated `/tmp` project. The first sandbox attempt could not open OMP's
read-only agent database; the valid runs used approved runtime access. No
active OMP package or Codex installation was changed. Raw traces are in
`/tmp/personal-skill-routing-task3/{baseline,green}/*.jsonl`.

Every prompt had the additional no-write sentence stated in the scenario
file. These tests measure guidance reads, tool availability checks, and the
proposed next action. They do **not** demonstrate actual extraction, rule or
schema file content, a worker dispatch, browser interactions, or an unassisted
approval gate.

| Case | Before at `1205961` | After checkpoint edit | Result |
| --- | --- | --- | --- |
| Inline UI task | Read `executing-plans`, `skillui`, and `design-tokens`; `skillui --help` succeeded; proposed extraction → tokens → components. | Same reads and command check; same order. | Pass before and after; no behavioral RED. |
| Subagent UI task | Read `subagent-driven-development`, both specialist skills, and implementer template; `skillui --help` succeeded; described staged briefs. | Same reads and check; brief explicitly carried extraction and token requirements to dependent component work. | Pass before and after; actual dispatch untested. |
| Rules authoring | Read `ogt-docs-rules`; attempted `ogt-docs-rules-code` and `ogt-docs-rules-code-back`, both unavailable; used root guidance without claiming specialized use. | Same checks and next action under approved execution. | Pass before and after. |
| As-built schema | Read `database-schema-documentation` and `executing-plans`; used implemented migrations/models as source. | Same reads; kept documentation after implementation. | Pass before and after. |
| Browser completion | Read `playwright-cli`; proposed browser checks before a completion claim, but did not check CLI availability and named `browser.open` rather than the skill's command. | Read `playwright-cli`; `which playwright-cli` succeeded; proposed `playwright-cli open` and fresh browser evidence before claiming completion. | Observable command-check improvement; no browser run in fixture. |
| Explicit early SkillUI | Read `skillui` and brainstorming; `skillui --help` succeeded; deferred extraction until approvals. | Same reads, command check, and gate. | Pass before and after; prompt itself prohibited writes. |

`node --test tests/pi/test-pi-extension.mjs` exited 0 (one test entry,
internally six checks). `git diff --check` exited 0. These checks establish
checkpoint wording and OMP guidance behavior in the isolated fixture. Fresh
Codex CLI and desktop runs against an installed fork, and real browser or
artifact execution, remain outside this task's evidence. The optional Codex
package archive test exited 9 because `zip` is absent from this environment;
its manifest check passed, but archive assertions could not run.

### Task 3 review correction: brief authority

The first Task 3 edit said to put selected personal-skill requirements in the
subagent dispatch context, conflicting with the generated brief's role as the
single requirements source. The revised checkpoint says to append them to the
generated task brief after `task-brief` runs, preserve extracted plan text,
reappend after regeneration, and point to the brief from the dispatch. One
fresh isolated OMP probe read the revised skill and proposed that exact
placement and extraction → tokens → components order. Its JSON trace is
`/tmp/personal-skill-routing-task3/green/subagent-brief-fix.jsonl`. The probe
forbade writing, so it verifies the stated workflow, not an actual augmented
brief or dispatched worker. `bash tests/claude-code/test-sdd-workspace.sh`
passed, including the generated-brief location; the Pi test and diff check
also passed.

## Task 5: installed-fork acceptance

The prior tables contain the before/after observations for every scenario in
`tests/personal-skill-routing/scenarios.md`. They are **isolated prompt probes**,
not evidence that the fork was installed in a normal session. The following
matrix separates those results from the fresh installed-fork checks. Raw traces
are in `/tmp/personal-skill-routing-codex-active/{explicit,automatic}.jsonl`
and `/tmp/personal-skill-routing-omp-active/{explicit,automatic,unavailable,approval-gate}.jsonl`.
OMP runs used 18.2.6 with `--mode=json --no-session --max-time=120` in an
isolated `/tmp` project, with normal plugin discovery. The first attempt hit a
read-only OMP agent database under sandboxing; the valid runs used approved
runtime access and exited 0.

| Harness | Baseline or before | Fresh installed fork | Limit |
| --- | --- | --- | --- |
| Codex CLI 0.155.0-alpha.16.3 | Isolated baseline explicit `design-tokens` and availability checks passed; it had no fork. | `superpowers@superpowers-dev` is installed and enabled from this checkout. Explicit trace read cached fork `using-superpowers`, its routing reference, `brainstorming`, and installed `design-tokens`; it deferred writing. Automatic billing trace read cached fork bootstrap, `brainstorming`, and installed `create-prd`, asked one user question, and wrote no file. | The automatic trace did not separately read the routing reference. Both prompts added a no-write sentence; an unassisted gate was not tested in CLI. The CLI remote catalog query failed, so its inventory alone cannot enumerate all remote entries; the desktop uninstall tool confirmed removal of the exact upstream identity. |
| Codex desktop | Existing task context can retain pre-install skills. | Local marketplace install and exact upstream uninstall completed through supported controls. | **Pending:** desktop was not restarted and no fresh desktop task was run. Use the guide's exact new-task prompts; do not treat CLI behavior as desktop verification. |
| OMP 18.2.6 | Initial active package was upstream `superpowers` 6.4.2. Earlier isolated fork probes used explicit extension loading; an initial `--plugin-dir` attempt that read upstream was excluded. | `omp plugin list --json` lists one enabled `superpowers` package at `~/.omp/plugins/node_modules/superpowers`; that path is a symlink resolving to this worktree. Normal fresh explicit trace read fork bootstrap, routing reference, and `design-tokens`. Automatic billing trace read `brainstorming`, `create-prd`, fork bootstrap, and routing reference; it asked one product question. Named missing-skill trace attempted `skill://missing-personal-skill`, got `Unknown skill`, and requested a readable installation without substituting. Unassisted preapproval trace read fork bootstrap, reference, `design-tokens`, and `brainstorming`; it performed only read-only inspection, wrote no files, and asked one settings-purpose question. | Normal installed OMP passes these four first-response cases. It did not generate a token file or exercise later approvals, extraction, dispatch, artifact quality, or browser behavior. |

The earlier Task 1–3 tables cover explicit availability, unreadable skill,
missing command and subskill, automatic unavailable, overlapping documents,
requested separate artifacts, design and planning choices, inline and subagent
execution choices, and browser verification. The live runs above confirm only
their four selected installed-fork cases; the remaining scenario verdicts are
from isolated sessions. The Task 2 UI-plan trace also had two blocked command
checks and lacked `ogt-docs-rules-code-front`, so its ordering result is not
proof that those tools worked.

All nine names have a selection condition and phase checkpoint in the shared
reference: `create-prd`, `design-brief`, `user-flow-diagram`, `trd`,
`database-schema-documentation`, `skillui`, `design-tokens`, `ogt-docs-rules`,
and `playwright-cli`. The branch diff changes Superpowers skills and routing
documentation; it adds no copy of those external skill directories or runtime
dependency on them. This is a private fork change; no upstream PR was opened.

The Pi post-compaction bootstrap assertion is in
`tests/pi/test-pi-extension.mjs`; its test result is recorded below. The
Codex zip package check could not run because `zip` is absent. A tar.gz archive
was created and inspected from a temporary normal checkout in Task 4 because
the packaging script expects `.git` to be a directory. That check found the
modified bootstrap and routing reference in the archive, but cannot rule out
a zip-only packaging regression.

### Final repository checks

At the installed-fork gate, `node --test tests/pi/test-pi-extension.mjs`
exited 0 (one Node test entry, zero failures). The test asserts that after
`session_compact` the bootstrap appears once after the compaction summary and
before the next user message. `bash tests/codex/test-marketplace-manifest.sh`
exited 0, `bash tests/claude-code/test-sdd-workspace.sh` exited 0, and
`git diff --check` exited 0. No Pi extension change was needed.
