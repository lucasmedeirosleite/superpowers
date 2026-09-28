# Install this Superpowers fork in Codex

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

3. Restart Codex desktop and open a **new task**. Ask it to read its installed `using-superpowers` skill and confirm that it refers to `personal-skill-routing.md`. Then check an explicit personal skill request and a task where a relevant skill should be selected automatically. An existing task can retain previously loaded skill context, so it does not verify the switch.

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
