#!/usr/bin/env python3
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

REPO_ROOT = Path(__file__).resolve().parents[2]
VALIDATOR_PATH = REPO_ROOT / "scripts" / "validate-codex-ai-roles.py"


def load_validator():
    spec = importlib.util.spec_from_file_location("codex_ai_roles", VALIDATOR_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class CodexAIRolesTest(unittest.TestCase):
    def setUp(self):
        self.validator = load_validator()

    def test_repository_roles_match_approved_matrix(self):
        roles = self.validator.load_roles(REPO_ROOT / "agents")
        self.assertEqual([], self.validator.validate_roles(roles))
        self.assertEqual(
            {
                "superpowers-explorer": ("gpt-5.6-luna", "low"),
                "superpowers-investigator": ("kimi-oauth/k3", "max"),
                "superpowers-implementer-mechanical": ("gpt-5.6-luna", "medium"),
                "superpowers-implementer": ("gpt-5.6-terra", "high"),
                "superpowers-implementer-complex": ("gpt-5.6-sol", "high"),
                "superpowers-task-reviewer": ("gpt-5.6-terra", "high"),
                "superpowers-re-reviewer": ("gpt-5.6-terra", "medium"),
                "superpowers-recovery": ("kimi-oauth/k3", "max"),
                "superpowers-final-reviewer": ("gpt-5.6-sol", "high"),
            },
            {
                name: (role["model"], role["model_reasoning_effort"])
                for name, role in roles.items()
            },
        )

    def test_rejects_duplicate_declared_name(self):
        roles = {
            "first": self.validator.expected_role("superpowers-explorer"),
            "second": self.validator.expected_role("superpowers-explorer"),
        }
        errors = self.validator.validate_roles(roles)
        self.assertTrue(any("duplicate role name" in error for error in errors))

    def test_rejects_gpt_reasoning_above_high(self):
        role = self.validator.expected_role("superpowers-implementer")
        role["model_reasoning_effort"] = "max"
        errors = self.validator.validate_roles({"superpowers-implementer": role})
        self.assertTrue(any("GPT-5.6 reasoning must not exceed high" in error for error in errors))

    def test_rejects_max_for_non_kimi_model(self):
        role = self.validator.expected_role("superpowers-final-reviewer")
        role["model_reasoning_effort"] = "max"
        errors = self.validator.validate_roles({"superpowers-final-reviewer": role})
        self.assertTrue(any("only Kimi K3 may use max" in error for error in errors))

    def test_catalog_must_contain_each_model_and_effort(self):
        roles = {
            "superpowers-investigator":
                self.validator.expected_role("superpowers-investigator")
        }
        catalog = {
            "models": [{
                "slug": "kimi-oauth/k3",
                "supported_reasoning_levels": [{"effort": "high"}],
            }]
        }
        errors = self.validator.validate_catalog(roles, catalog)
        self.assertEqual(
            ["superpowers-investigator: kimi-oauth/k3 does not support reasoning max"],
            errors,
        )


if __name__ == "__main__":
    unittest.main()
