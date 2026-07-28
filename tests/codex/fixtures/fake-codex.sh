#!/usr/bin/env bash
set -euo pipefail

STATE="${SUPERPOWERS_FAKE_CODEX_STATE:?}"

case "$*" in
  "--version")
    cat "$STATE/version"
    ;;
  "debug models")
    cat "$STATE/models.json"
    ;;
  "plugin marketplace list --json")
    cat "$STATE/marketplaces.json"
    ;;
  "plugin list --json")
    cat "$STATE/plugins.json"
    ;;
  "plugin marketplace add "*)
    printf '%s\n' "$*" >>"$STATE/commands.log"
    python3 - "$STATE/marketplaces.json" "$4" <<'PY'
import json, sys
payload = {"marketplaces": [{
    "name": "superpowers-dev",
    "root": sys.argv[2],
    "marketplaceSource": {"sourceType": "local", "source": sys.argv[2]},
}]}
json.dump(payload, open(sys.argv[1], "w", encoding="utf-8"))
PY
    printf '{"name":"superpowers-dev"}\n'
    ;;
  "plugin marketplace remove superpowers-dev --json")
    printf '%s\n' "$*" >>"$STATE/commands.log"
    printf '{"marketplaces":[]}\n' >"$STATE/marketplaces.json"
    printf '{"name":"superpowers-dev"}\n'
    ;;
  "plugin add superpowers@superpowers-dev --json")
    printf '%s\n' "$*" >>"$STATE/commands.log"
    python3 - "$STATE/plugins.json" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path, encoding="utf-8"))
data.setdefault("installed", []).append({
    "pluginId": "superpowers@superpowers-dev",
    "name": "superpowers",
    "marketplaceName": "superpowers-dev",
    "installed": True,
})
json.dump(data, open(path, "w", encoding="utf-8"))
PY
    printf '{"pluginId":"superpowers@superpowers-dev"}\n'
    ;;
  "plugin remove superpowers@superpowers-dev --json")
    printf '%s\n' "$*" >>"$STATE/commands.log"
    python3 - "$STATE/plugins.json" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path, encoding="utf-8"))
data["installed"] = [
    item for item in data.get("installed", [])
    if item.get("pluginId") != "superpowers@superpowers-dev"
]
json.dump(data, open(path, "w", encoding="utf-8"))
PY
    printf '{"pluginId":"superpowers@superpowers-dev"}\n'
    ;;
  *)
    printf 'unexpected fake Codex command: %s\n' "$*" >&2
    exit 2
    ;;
esac
