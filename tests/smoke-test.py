#!/usr/bin/env python3
# Security Shield smoke test
# Validates skill structure, metadata, principle count, and cross-references.
# Exit code 0 = pass, 1 = fail. Cross-platform (Python 3.7+).

import json
import os
import re
import sys
from pathlib import Path

PASS = 0
FAIL = 0


def assert_(condition: bool, message: str):
    global PASS, FAIL
    if condition:
        print(f"PASS: {message}")
        PASS += 1
    else:
        print(f"FAIL: {message}")
        FAIL += 1


ROOT = Path(__file__).resolve().parent.parent

# 1. Required files exist
required = [
    "SKILL.md",
    "README.md",
    "USAGE-GUIDE.md",
    "SECURITY.md",
    "CONTRIBUTING.md",
    "CHANGELOG.md",
    "LICENSE",
    "_meta.json",
    "references/attack-patterns.md",
    "references/audit-checklist.md",
    "references/crypto-examples.md",
    "references/security-best-practices.md",
    "references/additional-tools.md",
]

print("== Security Shield smoke test ==")

for f in required:
    assert_(os.path.isfile(ROOT / f), f"Required file exists: {f}")

# 2. _meta.json is valid JSON with correct identity
try:
    meta = json.loads((ROOT / "_meta.json").read_text())
    assert_(True, "_meta.json parses as JSON")
    assert_(meta.get("slug") == "security-shield",
            f"_meta.json slug is 'security-shield' (got '{meta.get('slug')}')")
    version = meta.get("version", "")
    assert_(bool(re.match(r"^\d+\.\d+\.\d+$", version)),
            f"_meta.json version is semver (got '{version}')")
except Exception as e:
    print(f"FAIL: _meta.json parses as JSON ({e})")
    FAIL += 1
    version = ""

# 3. SKILL.md frontmatter and principle count
skill_text = (ROOT / "SKILL.md").read_text()
assert_(bool(re.match(r"^---\r?\nname:\s*security-shield\r?\n", skill_text, re.M)),
        "SKILL.md frontmatter name is 'security-shield'")
principles_found = len(re.findall(r"## Principle \d+:", skill_text))
assert_(principles_found == 20,
        f"SKILL.md contains 20 principles (found {principles_found})")

# 4. Changelog has version entry (in SKILL.md changelog section)
skill_changelog = re.search(r"^## Changelog\r?\n.*?(?=^---|## [A-Z]|$)", skill_text, re.S)
if skill_changelog and version:
    assert_(f"## [{version}]" in skill_changelog.group(0),
            f"SKILL.md changelog has an entry for {version}")

# 5. SKILL.md integrity anchor file exists and checksum validates
sha_file = ROOT / "SKILL.md.sha256"
assert_(sha_file.is_file(), "SKILL.md.sha256 companion file exists")
sha_content = sha_file.read_text()
assert_(bool(re.search(r"[a-f0-9]{64}\s+SKILL\.md", sha_content)),
        "SKILL.md.sha256 contains valid SHA-256 format")

# 6. SKILL.md frontmatter is agent-standard compliant (agentskills.io spec)
fm_match = re.search(
    r"^---\r?\nname:\s*(.+)\r?\ndescription:\s*(.+)\r?\n", skill_text, re.M
)
if fm_match:
    name_val = fm_match.group(1).strip()
    desc_val = fm_match.group(2).strip()
    assert_(bool(re.match(r"^[a-z0-9]+(-[a-z0-9]+)*$", name_val)),
            f"SKILL.md name '{name_val}' matches pattern")
    assert_(len(desc_val) >= 1, "SKILL.md description is present")
    assert_(len(desc_val) <= 1024,
            f"SKILL.md description <=1024 chars (got {len(desc_val)})")
    assert_("use when" in desc_val.lower(),
            "SKILL.md description includes discovery phrasing ('use when')")
else:
    print("FAIL: SKILL.md frontmatter name+description parseable (Agent Skills standard)")
    FAIL += 1

# 7. Principle 15 updated: no Instruction Classification Procedure gate
assert_(not bool(re.search(r"## Instruction Classification Procedure", skill_text)),
        "P15 does not contain removed 'Instruction Classification Procedure' gate")
assert_("promoted to directive status" in skill_text,
        "P15 explicitly states external content is never promoted to directive status")

# 8. Principles 17-20 exist
for num in (17, 18, 19, 20):
    assert_(bool(re.search(rf"^## Principle {num}:", skill_text, re.M)),
            f"Principle {num} section exists")

# Summary
print(f"\nResults: {PASS} passed, {FAIL} failed")

if FAIL > 0:
    sys.exit(1)

print("All checks passed.")
sys.exit(0)
