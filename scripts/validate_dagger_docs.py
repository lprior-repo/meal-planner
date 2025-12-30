#!/usr/bin/env python3
"""Validate Dagger documentation files according to DOC_TRANSFORMER Step 7 rules."""

import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def validate_file(filepath: Path, all_files: set[str]) -> dict[str, Any]:
    """Validate a single markdown file against all rules."""
    errors = []
    warnings = []

    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception as e:
        errors.append({"rule": "READ_ERROR", "message": f"Could not read file: {e}"})
        return {"errors": errors, "warnings": warnings}

    lines = content.split("\n")

    # V001: single_h1 - Exactly 1 line matches ^# [^#]
    h1_count = sum(1 for line in lines if re.match(r"^# [^#]", line))
    if h1_count != 1:
        errors.append(
            {"rule": "V001", "message": f"Expected 1 H1 heading, found {h1_count}"}
        )

    # V002: frontmatter_exists - First line is --- AND second --- within first 50 lines
    has_frontmatter = False
    frontmatter_end = 0
    frontmatter_text = ""
    if lines and lines[0].strip() == "---":
        for i, line in enumerate(lines[1:51], start=1):
            if line.strip() == "---":
                has_frontmatter = True
                frontmatter_end = i
                frontmatter_text = "\n".join(lines[1:frontmatter_end])
                break
    if not has_frontmatter:
        errors.append({"rule": "V002", "message": "Missing or malformed frontmatter"})

    # V003: required_fields - Frontmatter contains id/title/category/tags
    if has_frontmatter:
        frontmatter_text = "\n".join(lines[1:frontmatter_end])
        required_fields = ["id:", "title:", "category:", "tags:"]
        missing_fields = []
        for field in required_fields:
            if field not in frontmatter_text:
                missing_fields.append(field.rstrip(":"))
        if missing_fields:
            errors.append(
                {
                    "rule": "V003",
                    "message": f"Missing fields: {', '.join(missing_fields)}",
                }
            )

    # V004: no_skipped_headings - Each heading level <= previous + 1
    prev_level = 0
    for i, line in enumerate(lines, start=1):
        heading_match = re.match(r"^(#{1,6})\s", line)
        if heading_match:
            level = len(heading_match.group(1))
            if prev_level > 0 and level > prev_level + 1:
                errors.append(
                    {
                        "rule": "V004",
                        "message": f"Skipped heading level at line {i}: H{prev_level} to H{level}",
                    }
                )
            prev_level = level

    # V005: links_resolve - Every ](./ link points to existing file
    link_pattern = re.compile(r"\]\(\./([^)#]+)")
    for i, line in enumerate(lines, start=1):
        for match in link_pattern.finditer(line):
            linked_file = match.group(1)
            # Normalize the linked file path - check in same directory first
            linked_path = (filepath.parent / linked_file).resolve()
            if linked_path.exists():
                continue
            # Check just the filename in the same directory
            if linked_file in all_files:
                continue
            # Check in parent directory (for COMPASS.md etc)
            parent_path = (filepath.parent.parent / linked_file).resolve()
            if parent_path.exists():
                continue
            errors.append(
                {
                    "rule": "V005",
                    "message": f"Broken link at line {i}: ./{linked_file}",
                }
            )

    # V006: min_tags - tags array has 3+ items
    if has_frontmatter:
        tags_match = re.search(r"tags:\s*\[([^\]]*)\]", frontmatter_text)
        if tags_match:
            tags_str = tags_match.group(1)
            # Count quoted strings
            tags = re.findall(r'"[^"]*"', tags_str)
            if len(tags) < 3:
                warnings.append(
                    {"rule": "V006", "message": f"Only {len(tags)} tags, recommend 3+"}
                )
        else:
            warnings.append({"rule": "V006", "message": "Could not parse tags array"})

    # V007: has_context - Contains > **Context**:
    has_context = "> **Context**:" in content
    if not has_context:
        warnings.append({"rule": "V007", "message": "No context block"})

    # V008: has_see_also - Contains ## See Also
    has_see_also = "## See Also" in content
    if not has_see_also:
        warnings.append({"rule": "V008", "message": "No See Also section"})

    # V009: code_has_language - Every ``` has text after it
    code_block_pattern = re.compile(r"^```\s*$", re.MULTILINE)
    unmarked_blocks = code_block_pattern.findall(content)
    if unmarked_blocks:
        warnings.append(
            {
                "rule": "V009",
                "message": f"{len(unmarked_blocks)} code block(s) without language specifier",
            }
        )

    return {"errors": errors, "warnings": warnings}


def main():
    docs_dir = Path("/home/lewis/src/meal-planner/docs/dagger/_indexed/docs")
    output_path = Path(
        "/home/lewis/src/meal-planner/docs/dagger/_indexed/validation_report.json"
    )

    # Get all markdown files
    md_files = list(docs_dir.glob("*.md"))
    all_filenames = {f.name for f in md_files}

    # Initialize counters
    files_checked = len(md_files)
    files_passed = 0
    files_failed = 0
    total_errors = 0
    total_warnings = 0

    # Track by rule
    rules = ["V001", "V002", "V003", "V004", "V005", "V006", "V007", "V008", "V009"]
    by_rule = {rule: {"passed": 0, "failed": 0} for rule in rules}

    failures = []

    for filepath in sorted(md_files):
        result = validate_file(filepath, all_filenames)

        file_errors = result["errors"]
        file_warnings = result["warnings"]

        total_errors += len(file_errors)
        total_warnings += len(file_warnings)

        # Track which rules failed for this file
        failed_rules = set()
        for err in file_errors:
            if err["rule"] in rules:
                failed_rules.add(err["rule"])
        for warn in file_warnings:
            if warn["rule"] in rules:
                failed_rules.add(warn["rule"])

        # Update by_rule counts
        for rule in rules:
            if rule in failed_rules:
                by_rule[rule]["failed"] += 1
            else:
                by_rule[rule]["passed"] += 1

        if file_errors:
            files_failed += 1
            failures.append(
                {
                    "file": filepath.name,
                    "errors": file_errors,
                    "warnings": file_warnings,
                }
            )
        else:
            files_passed += 1
            # Still record warnings even for passed files
            if file_warnings:
                failures.append(
                    {"file": filepath.name, "errors": [], "warnings": file_warnings}
                )

    # Build report
    report = {
        "run_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "summary": {
            "files_checked": files_checked,
            "files_passed": files_passed,
            "files_failed": files_failed,
            "total_errors": total_errors,
            "total_warnings": total_warnings,
        },
        "by_rule": by_rule,
        "failures": [f for f in failures if f["errors"] or f["warnings"]],
    }

    # Write report
    output_path.write_text(json.dumps(report, indent=2), encoding="utf-8")

    # Print checkpoint
    print(
        f"VALIDATE: {files_passed}/{files_checked} files passed. {total_errors} errors {total_warnings} warnings"
    )

    # Print breakdown by rule
    print("\nBreakdown by rule:")
    for rule in rules:
        passed = by_rule[rule]["passed"]
        failed = by_rule[rule]["failed"]
        status = "OK" if failed == 0 else "ISSUES"
        print(f"  {rule}: {passed} passed, {failed} failed [{status}]")

    return report


if __name__ == "__main__":
    main()
