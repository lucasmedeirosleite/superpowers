# Install this Superpowers fork in Codex and OMP

This private fork is published to Codex from the checkout as `superpowers@superpowers-dev`. Run the commands below from the checkout you want to use. Keep its directory in place while the marketplace is registered.

## Install

1. Record any currently installed upstream Superpowers identity before changing it:

   ```sh
   codex plugin list --json
   ```

   In the `installed` array, find entries whose `name` is `superpowers`. Record each upstream `pluginId` and its `enabled` state. The marketplace suffix is part of the identity; do not assume that every `superpowers` entry is this fork.

2. Register this checkout and install its entry:

   ```sh
   codex plugin marketplace add "$(git rev-parse --show-toplevel)"
   codex plugin marketplace list --json
   codex plugin add superpowers@superpowers-dev
   codex plugin list --json
   ```

   Confirm that `superpowers@superpowers-dev` is installed and enabled and that the `superpowers-dev` marketplace points to this checkout. Remove each **enabled upstream** Superpowers entry by its exact recorded `pluginId`, for example `codex plugin remove 'superpowers@RECORDED_MARKETPLACE'`. Run `codex plugin list --json` again and confirm that the fork is the only enabled entry named `superpowers`. Codex's CLI supports removal by exact plugin ID; it does not expose a plugin disable command.

3. Restart Codex desktop and open a **new task**. Ask it to read its installed `using-superpowers` skill and confirm that it refers to `personal-skill-routing.md`. Then use the exact acceptance prompts below in new tasks. An existing task can retain previously loaded skill context, so it does not verify the switch.

   - Bootstrap: `Read your installed using-superpowers skill. Report the installed path and whether it points to references/personal-skill-routing.md. Do not change files.`
   - Explicit request: `Use design-tokens for a new settings page. We have not approved the visual direction or implementation plan. The deadline is in an hour; get started now. Do not write files in this evaluation; describe the exact next action.`
   - Automatic selection: `We need to define users, outcomes, and release scope for a new team billing feature. Help shape the product requirements before technical design. Do not write files in this evaluation; describe the exact next action.`

   Confirm that the bootstrap path belongs to `superpowers@superpowers-dev`, the explicit task reads `design-tokens` and defers token creation, and the automatic task reads `create-prd` without creating a separate document. Record observed paths and responses. The desktop check is still pending; an installed inventory and CLI session do not prove what a fresh desktop task loads.

## Refresh after editing this checkout

Codex installs a cached copy of a local plugin. Changes to `skills/` in this checkout do not update that copy automatically. Refresh through the supported plugin commands, then start a new Codex task:

```sh
codex plugin remove superpowers@superpowers-dev
codex plugin add superpowers@superpowers-dev
codex plugin list --json
```

Restart Codex desktop after refreshing. Read the installed `using-superpowers` skill in a fresh task to verify the changed routing text is present. Do not edit Codex's plugin cache directly.

## Roll back to the previous upstream plugin

Use the exact upstream `pluginId` recorded during installation:

```sh
codex plugin remove superpowers@superpowers-dev
codex plugin add 'superpowers@RECORDED_MARKETPLACE'
codex plugin list --json
```

Confirm the upstream entry is installed and enabled and that no fork entry remains enabled. Restart Codex desktop and use a new task. If this local marketplace is no longer needed, remove its registration with `codex plugin marketplace remove superpowers-dev` after removing the fork.

The repository's `.codex-plugin/plugin.json` deliberately declares `"hooks": {}`. This prevents Codex from discovering the separate Claude Code `hooks/hooks.json` SessionStart hook when it installs this repository. Keep that empty object in place when refreshing or packaging the plugin.

## Link this fork in OMP

From this checkout, record the current OMP package and then link the fork through OMP's plugin manager:

```sh
omp plugin list --json
omp plugin link "$(git rev-parse --show-toplevel)"
omp plugin list --json
```

The OMP inventory can display `~/.omp/plugins/node_modules/superpowers` as the package path even when that path is a symlink. Resolve that path and confirm it points to this checkout. Start a fresh OMP session and read `skill://using-superpowers`; its bootstrap should point to `references/personal-skill-routing.md`. Keep the linked checkout at its current path. OMP reads the link target directly, so edits here are available to a new OMP session without a package refresh. Restart any existing OMP session to get fresh skill context.

If this checkout moves, run `omp plugin link "$(git rev-parse --show-toplevel)"` from the new location and confirm the symlink target again. To roll back, use `omp plugin uninstall superpowers` and reinstall the previously recorded package with `omp plugin install <recorded-package-source>`; then verify `omp plugin list --json` and a fresh bootstrap read. Do not edit OMP's package directory or symlink by hand. OMP's `--dry-run` attempted a package removal in this environment, so do not use it as a safety check for this replacement.
