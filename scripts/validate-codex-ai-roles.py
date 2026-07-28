#!/usr/bin/env python3
import argparse
import json
from pathlib import Path
import sys
import tomllib

EXPECTED = {
    "superpowers-explorer": ("gpt-5.6-luna", "low"),
    "superpowers-investigator": ("kimi-oauth/k3", "max"),
    "superpowers-implementer-mechanical": ("gpt-5.6-luna", "medium"),
    "superpowers-implementer": ("gpt-5.6-terra", "high"),
    "superpowers-implementer-complex": ("gpt-5.6-sol", "high"),
    "superpowers-task-reviewer": ("gpt-5.6-terra", "high"),
    "superpowers-re-reviewer": ("gpt-5.6-terra", "medium"),
    "superpowers-recovery": ("kimi-oauth/k3", "max"),
    "superpowers-final-reviewer": ("gpt-5.6-sol", "high"),
}
GPT_EFFORTS = {"low": 0, "medium": 1, "high": 2}
REQUIRED_FIELDS = {
    "name",
    "description",
    "model",
    "model_reasoning_effort",
    "developer_instructions",
}


def expected_role(name):
    model, effort = EXPECTED[name]
    return {
        "name": name,
        "description": "test description",
        "model": model,
        "model_reasoning_effort": effort,
        "developer_instructions": "test instructions",
    }


def load_roles(roles_dir):
    roles = {}
    for path in sorted(Path(roles_dir).glob("*.toml")):
        roles[path.stem] = tomllib.loads(path.read_text(encoding="utf-8"))
    return roles


def validate_roles(roles):
    errors = []
    declared_names = [role.get("name") for role in roles.values()]
    if len(declared_names) != len(set(declared_names)):
        errors.append("duplicate role name")
    if set(roles) != set(EXPECTED):
        errors.append(
            "role filenames differ: expected "
            + ", ".join(sorted(EXPECTED))
            + "; got "
            + ", ".join(sorted(roles))
        )
    for filename, role in sorted(roles.items()):
        missing = sorted(REQUIRED_FIELDS - role.keys())
        if missing:
            errors.append(f"{filename}: missing fields {', '.join(missing)}")
            continue
        if role["name"] != filename:
            errors.append(f"{filename}: declared name is {role['name']}")
        expected = EXPECTED.get(filename)
        actual = (role["model"], role["model_reasoning_effort"])
        if expected is not None and actual != expected:
            errors.append(f"{filename}: expected {expected}, got {actual}")
        if not role["description"].strip() or not role["developer_instructions"].strip():
            errors.append(f"{filename}: description and instructions must be non-empty")
        effort = role["model_reasoning_effort"]
        if role["model"].startswith("gpt-5.6-") and effort not in GPT_EFFORTS:
            errors.append(f"{filename}: GPT-5.6 reasoning must not exceed high")
        if effort == "max" and role["model"] != "kimi-oauth/k3":
            errors.append(f"{filename}: only Kimi K3 may use max")
    return errors


def validate_catalog(roles, catalog):
    errors = []
    models = {model.get("slug"): model for model in catalog.get("models", [])}
    for name, role in sorted(roles.items()):
        model = models.get(role["model"])
        if model is None:
            errors.append(f"{name}: model {role['model']} is unavailable")
            continue
        efforts = {
            item["effort"]
            for item in model.get("supported_reasoning_levels", [])
            if "effort" in item
        }
        if role["model_reasoning_effort"] not in efforts:
            errors.append(
                f"{name}: {role['model']} does not support reasoning "
                f"{role['model_reasoning_effort']}"
            )
    return errors


def parse_args():
    repo_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument("--roles-dir", type=Path, default=repo_root / "agents")
    parser.add_argument("--catalog", type=Path)
    return parser.parse_args()


def main():
    args = parse_args()
    roles = load_roles(args.roles_dir)
    errors = validate_roles(roles)
    if args.catalog:
        with args.catalog.open(encoding="utf-8") as handle:
            errors.extend(validate_catalog(roles, json.load(handle)))
    if errors:
        for error in sorted(errors):
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("Codex AI roles valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
