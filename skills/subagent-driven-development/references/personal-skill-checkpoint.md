# Personal Skill Checkpoint

Read this before dispatching a task involving design-system extraction,
tokens, enforceable rules, or documentation of a completed schema.

Consult `../../using-superpowers/references/personal-skill-routing.md`
(relative to this file) before dispatch. Check the relevant `skillui`,
`design-tokens`, `ogt-docs-rules`, or `database-schema-documentation` skill
and its required command or subskill.

After `task-brief` extracts the plan task, append a concise **Personal skill
requirements** section to that generated brief: selected available skills,
their task-specific method, and dependency order. Tell the implementer there
to read those skills in its own environment. Keep extraction and tokens before
dependent components, and as-built schema documentation after implementation.

Preserve the extracted plan text. The script overwrites the brief when rerun,
so append this section again on a retry. In the dispatch, point to the brief
without copying these requirements into context. Follow the routing
reference's unavailable-skill rule and keep the approved plan's writing gates.
