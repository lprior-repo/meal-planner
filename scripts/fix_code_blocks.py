#!/usr/bin/env python3
"""Fix unlabeled code blocks by inferring language from content.

Usage:
    python scripts/fix_code_blocks.py [--dry-run]
"""

import re
import sys
from pathlib import Path

DOCS_DIR = Path("docs")
EXCLUDE_DIRS = {"_indexed", "node_modules", ".git"}


def infer_language(code: str) -> str:
    """Infer programming language from code content."""
    code_lower = code.lower().strip()
    first_line = code_lower.split("\n")[0] if code_lower else ""

    # Shell/Bash indicators
    if any(
        x in first_line
        for x in [
            "$",
            "#!",
            "sudo ",
            "apt ",
            "docker ",
            "cd ",
            "mkdir ",
            "pip ",
            "npm ",
            "yarn ",
            "git ",
            "curl ",
            "wget ",
            "chmod ",
            "chown ",
            "export ",
            "source ",
            "echo ",
            "cat ",
            "ls ",
            "rm ",
            "cp ",
            "mv ",
        ]
    ):
        return "bash"
    if first_line.startswith(
        ("docker-compose", "docker ", "wmill ", "cargo ", "rustup ")
    ):
        return "bash"
    if re.match(r"^[a-z_]+\s*=", first_line):  # VAR=value
        return "bash"

    # YAML indicators
    if re.match(r"^[a-z_-]+:\s*", first_line) or first_line.startswith("---"):
        return "yaml"
    if "version:" in code_lower[:200] or "services:" in code_lower[:200]:
        return "yaml"

    # JSON indicators
    if first_line.startswith(("{", "[")):
        return "json"

    # Python indicators
    if (
        "import " in code_lower[:200]
        or "def " in code_lower[:200]
        or "class " in code_lower[:200]
    ):
        if "from typing import" in code_lower or "async def" in code_lower:
            return "python"
        return "python"

    # Rust indicators
    if (
        "fn " in code_lower[:200]
        or "let " in code_lower[:200]
        or "use " in code_lower[:200]
    ):
        if "::" in code or "->" in code or "pub fn" in code_lower:
            return "rust"
    if (
        "struct " in code_lower[:200]
        or "impl " in code_lower[:200]
        or "#[derive" in code_lower[:200]
    ):
        return "rust"

    # TypeScript/JavaScript indicators
    if (
        "const " in code_lower[:200]
        or "function " in code_lower[:200]
        or "export " in code_lower[:200]
    ):
        if (
            ": string" in code_lower
            or ": number" in code_lower
            or "interface " in code_lower
        ):
            return "typescript"
        return "javascript"
    if "async function" in code_lower or "await " in code_lower:
        return "typescript"

    # SQL indicators
    if any(
        x in code_lower[:100]
        for x in [
            "select ",
            "insert ",
            "update ",
            "delete ",
            "create table",
            "alter table",
            "drop ",
        ]
    ):
        return "sql"

    # HTML indicators
    if first_line.startswith(("<", "<!")) or "</" in code[:200]:
        return "html"

    # INI/TOML indicators
    if first_line.startswith("[") and "]" in first_line and "=" in code:
        if "[[" in code or "true" in code_lower or "false" in code_lower:
            return "toml"
        return "ini"

    # Nginx/Apache config
    if "server {" in code_lower or "location " in code_lower:
        return "nginx"

    # Dockerfile
    if first_line.startswith(
        ("from ", "run ", "copy ", "env ", "workdir ", "cmd ", "entrypoint ")
    ):
        return "dockerfile"

    # Environment variables
    if re.match(r"^[A-Z_]+=", code.strip()):
        return "bash"

    # Text/output (fallback for things like error messages, logs)
    if any(x in code_lower[:100] for x in ["error:", "warning:", "info:", "debug:"]):
        return "text"

    # Default to text for unknown
    return "text"


def fix_code_blocks(content: str) -> tuple[str, int]:
    """Fix unlabeled code blocks in content. Returns (new_content, fix_count)."""

    fixes = 0
    lines = content.split("\n")
    result = []
    in_code_block = False

    for line in lines:
        # Check if this is a code fence
        if line.startswith("```"):
            if not in_code_block:
                # Opening a code block
                in_code_block = True
                if line == "```":
                    # No language specified - mark for second pass
                    result.append("```__NEEDS_LANG__")
                else:
                    result.append(line)
            else:
                # Closing a code block
                in_code_block = False
                result.append(line)
        else:
            result.append(line)

    # Second pass: fix the __NEEDS_LANG__ markers
    content = "\n".join(result)

    def replace_unlabeled(match):
        nonlocal fixes
        code = match.group(1)
        lang = infer_language(code)
        fixes += 1
        return f"```{lang}\n{code}```"

    content = re.sub(
        r"```__NEEDS_LANG__\n(.*?)```", replace_unlabeled, content, flags=re.DOTALL
    )

    return content, fixes


def process_file(filepath: Path, dry_run: bool = False) -> int:
    """Process a single file. Returns number of fixes."""
    content = filepath.read_text(encoding="utf-8", errors="ignore")

    # Check if there are unlabeled code blocks
    if "```\n" not in content:
        return 0

    new_content, fixes = fix_code_blocks(content)

    if fixes > 0:
        if dry_run:
            print(f"  Would fix {fixes} blocks in {filepath}")
        else:
            filepath.write_text(new_content, encoding="utf-8")
            print(f"  Fixed {fixes} blocks in {filepath}")

    return fixes


def main():
    dry_run = "--dry-run" in sys.argv

    if dry_run:
        print("DRY RUN - no changes will be made\n")

    total_fixes = 0
    files_fixed = 0

    # Process both .md and .mdx files
    for pattern in ["*.md", "*.mdx"]:
        for md_file in DOCS_DIR.rglob(pattern):
            # Skip excluded directories
            if any(excl in md_file.parts for excl in EXCLUDE_DIRS):
                continue

            fixes = process_file(md_file, dry_run)
            if fixes > 0:
                total_fixes += fixes
                files_fixed += 1

    print(
        f"\n{'Would fix' if dry_run else 'Fixed'} {total_fixes} code blocks in {files_fixed} files"
    )


if __name__ == "__main__":
    main()
