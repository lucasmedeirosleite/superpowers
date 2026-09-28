# Personal skill routing: Task 1 evaluation

Date: 2026-09-28. Base commit: `52645a6`. Prompts and acceptance criteria are in `tests/personal-skill-routing/scenarios.md`. All project writes were confined to `/tmp/personal-skill-routing-*`.

## Harness provenance and correction

The initial OMP command used `--plugin-dir <checkout>` while the active upstream OMP package remained installed. Its trace resolved `skill://using-superpowers` and `skill://brainstorming` from upstream, and did not read the new reference. The earlier claim that this was fork GREEN evidence was **incorrect**. Those runs are excluded from the fork verdicts below.

For valid OMP A/B runs, I archived base commit `52645a6` to `/tmp/personal-skill-routing-base-repo` and invoked each package with `--no-extensions -e <package>/.pi/extensions/superpowers.ts --plugin-dir <package>` and isolated `PI_PACKAGE_DIR=/tmp/personal-skill-routing-omp-packages-{base,green}`. The explicit extension is the only bootstrap injected for these runs. In the exact `design-tokens` baseline, the `skill://using-superpowers` read result had no `personal-skill-routing.md` pointer; in the fork run it did, and the trace separately read `skill://using-superpowers/references/personal-skill-routing.md` with `## Selection`. No active OMP installation was changed.

Codex CLI 0.155.0-alpha.16.3 ran from an isolated `CODEX_HOME` with installed personal skills. It did **not** load this fork; its results are baseline/fixture observations only. Fork activation through a local Codex marketplace belongs to Task 4. OMP version was 18.2.6.

## Baseline before the Task 1 edit

| Case | Observed result | Verdict |
| --- | --- | --- |
| Exact explicit `design-tokens`, isolated base OMP | Read `skill://using-superpowers`, `skill://brainstorming`, and `skill://design-tokens`; held the writing gate. Did not read a routing reference because none existed. | Existing behavior **passed** named skill reading and gate; reference absent. No behavioral RED claimed for this valid A/B run. |
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
| Exact explicit `design-tokens` before approval | Read fork bootstrap, shared reference, and `design-tokens`; final: “Reading the requested skill now does not authorize executing its file-writing steps.” No files written. | Pass. |
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
