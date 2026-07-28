#!/usr/bin/env bash

variant_die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

variant_repo_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
  cd "$script_dir/.." && pwd
}

variant_codex_home() {
  printf '%s\n' "${SUPERPOWERS_CODEX_HOME:-${CODEX_HOME:-$HOME/.codex}}"
}

variant_codex_bin() {
  printf '%s\n' "${SUPERPOWERS_CODEX_BIN:-codex}"
}

variant_realpath() {
  python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

variant_version_at_least_0145() {
  python3 - "$1" <<'PY'
import re, sys
match = re.search(r"(\d+)\.(\d+)\.(\d+)", sys.argv[1])
raise SystemExit(0 if match and tuple(map(int, match.groups())) >= (0, 145, 0) else 1)
PY
}

variant_marketplace_json() {
  env CODEX_HOME="$CODEX_HOME_PATH" \
    "$CODEX_BIN_PATH" plugin marketplace list --json
}

variant_plugins_json() {
  env CODEX_HOME="$CODEX_HOME_PATH" \
    "$CODEX_BIN_PATH" plugin list --json
}

variant_validate_plugins_json() {
  local json_file="$1"
  python3 - "$json_file" <<'PY'
import json
import sys

try:
    data = json.load(open(sys.argv[1], encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("expected an object with an installed list")
    installed = data.get("installed", [])
    if not isinstance(installed, list):
        raise ValueError("expected an object with an installed list")
    if not all(isinstance(item, dict) for item in installed):
        raise ValueError("installed entries must be objects")
except (OSError, ValueError, json.JSONDecodeError) as error:
    print(f"invalid Codex plugin list JSON: {error}", file=sys.stderr)
    raise SystemExit(1)
PY
}

variant_marketplace_root() {
  local json_file="$1"
  local marketplace_name="$2"
  python3 - "$json_file" "$marketplace_name" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
for item in data.get("marketplaces", []):
    if item.get("name") == sys.argv[2]:
        source = item.get("marketplaceSource", {}).get("source")
        print(source or item.get("root", ""))
        break
PY
}

variant_installed_superpowers_ids() {
  local json_file="$1"
  python3 - "$json_file" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
for item in data.get("installed", []):
    if item.get("name") == "superpowers" and item.get("installed", True):
        print(item["pluginId"])
PY
}

variant_plugin_is_installed() {
  local json_file="$1"
  local plugin_id="$2"
  python3 - "$json_file" "$plugin_id" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
raise SystemExit(0 if any(
    item.get("pluginId") == sys.argv[2] and item.get("installed", True)
    for item in data.get("installed", [])
) else 1)
PY
}

variant_state_value() {
  local state_file="$1"
  local key="$2"
  python3 - "$state_file" "$key" <<'PY'
import json, sys
value = json.load(open(sys.argv[1], encoding="utf-8"))[sys.argv[2]]
print(str(value).lower() if isinstance(value, bool) else value)
PY
}

variant_write_state_atomically() {
  local state_file="$1"
  local repo_root="$2"
  local agents_link="$3"
  local marketplace_added="$4"
  local plugin_added="$5"
  local agents_link_added="$6"
  local temp_state
  temp_state="$(mktemp "$(dirname "$state_file")/.superpowers-variant-state.XXXXXX")"
  python3 - "$temp_state" "$repo_root" "$agents_link" \
    "$marketplace_added" "$plugin_added" "$agents_link_added" <<'PY'
import json, sys
payload = {
    "schema": 1,
    "repo_root": sys.argv[2],
    "agents_link": sys.argv[3],
    "marketplace_name": "superpowers-dev",
    "marketplace_added": sys.argv[4] == "true",
    "plugin_id": "superpowers@superpowers-dev",
    "plugin_added": sys.argv[5] == "true",
    "agents_link_added": sys.argv[6] == "true",
}
with open(sys.argv[1], "w", encoding="utf-8") as handle:
    json.dump(payload, handle, indent=2)
    handle.write("\n")
PY
  mv "$temp_state" "$state_file"
}

variant_link_is_owned() {
  local target="$1"
  local source="$2"
  [[ -L "$target" ]] &&
    [[ "$(variant_realpath "$target")" == "$(variant_realpath "$source")" ]]
}
