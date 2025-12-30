#!/usr/bin/env python3
"""
DOC_TRANSFORMER Step 4: Transform Dagger documentation files.

This script transforms markdown files according to the doc_transformer spec:
- Fix headings (ensure single H1, no skipped levels, flatten deep headings)
- Generate frontmatter with id, title, category, tags
- Add context block after H1
- Rewrite internal links using link_map
- Add See Also section
- Write transformed files to output directory
"""

import json
import re
import os
from pathlib import Path
from datetime import datetime


def load_manifest(manifest_path: str) -> dict:
    """Load the manifest file."""
    with open(manifest_path, "r") as f:
        return json.load(f)


def extract_tags(content: str, category: str, title: str) -> list:
    """Extract 3-5 relevant tags from content."""
    tags = set()

    # Add category as first tag
    tags.add(category)

    # Common Dagger-related keywords to look for
    keywords = [
        "container",
        "docker",
        "ci",
        "cd",
        "pipeline",
        "module",
        "function",
        "cache",
        "secret",
        "service",
        "directory",
        "file",
        "git",
        "github",
        "gitlab",
        "jenkins",
        "circleci",
        "kubernetes",
        "deployment",
        "sdk",
        "go",
        "python",
        "typescript",
        "php",
        "java",
        "api",
        "graphql",
        "llm",
        "agent",
        "ai",
        "build",
        "test",
        "debug",
        "trace",
        "cloud",
        "shell",
        "cli",
        "config",
        "auth",
        "oauth",
        "webhook",
        "workflow",
        "environment",
        "env",
        "toolchain",
        "interface",
        "type",
        "error",
        "troubleshoot",
        "install",
        "setup",
        "quickstart",
        "tutorial",
    ]

    content_lower = content.lower()
    title_lower = title.lower()

    for kw in keywords:
        if kw in title_lower or content_lower.count(kw) >= 3:
            tags.add(kw)
            if len(tags) >= 5:
                break

    return list(tags)[:5]


def fix_headings(content: str, title: str) -> str:
    """Fix heading issues in the content."""
    lines = content.split("\n")
    result_lines = []
    h1_found = False
    prev_level = 0

    for line in lines:
        heading_match = re.match(r"^(#{1,6})\s+(.+)$", line)

        if heading_match:
            hashes = heading_match.group(1)
            heading_text = heading_match.group(2)
            level = len(hashes)

            if level == 1:
                if not h1_found:
                    h1_found = True
                    result_lines.append(line)
                else:
                    # Convert subsequent H1 to H2
                    result_lines.append(f"## {heading_text}")
                prev_level = 1 if not h1_found else 2
            else:
                # Fix skipped levels
                if prev_level > 0 and level > prev_level + 1:
                    level = prev_level + 1

                # Flatten level 5/6 to level 4
                if level > 4:
                    level = 4

                result_lines.append(f"{'#' * level} {heading_text}")
                prev_level = level
        else:
            result_lines.append(line)

    # If no H1 found, insert title at start
    if not h1_found:
        result_lines.insert(0, f"# {title}")
        result_lines.insert(1, "")

    return "\n".join(result_lines)


def generate_frontmatter(file_info: dict, tags: list) -> str:
    """Generate YAML frontmatter."""
    tag_str = ", ".join(f'"{t}"' for t in tags)
    return f"""---
id: {file_info["id"]}
title: "{file_info["analysis"]["title"]}"
category: {file_info["analysis"]["category"]}
tags: [{tag_str}]
---
"""


def has_context_block(content: str) -> bool:
    """Check if content already has a context block within first 500 chars after frontmatter."""
    # Remove frontmatter if present
    if content.startswith("---"):
        end_fm = content.find("---", 3)
        if end_fm != -1:
            content = content[end_fm + 3 :]

    first_500 = content[:500]
    return "> **Context**:" in first_500


def add_context_block(content: str, first_paragraph: str) -> str:
    """Add context block after H1 if not present."""
    if has_context_block(content):
        return content

    # Truncate first paragraph to 150 chars
    context_text = first_paragraph[:150].strip()
    if len(first_paragraph) > 150:
        context_text += "..."

    context_block = f"\n> **Context**: {context_text}\n"

    # Find the first H1 and insert after it
    lines = content.split("\n")
    result_lines = []
    h1_inserted = False

    for i, line in enumerate(lines):
        result_lines.append(line)
        if not h1_inserted and re.match(r"^#\s+", line):
            result_lines.append(context_block)
            h1_inserted = True

    return "\n".join(result_lines)


def build_link_map(files: list) -> dict:
    """Build a mapping from source paths to new filenames."""
    link_map = {}
    for f in files:
        source = f["source_path"]
        filename = f["filename"]

        # Map various forms of the source path
        link_map[source] = filename
        link_map[f"/{source}"] = filename
        link_map[source.replace(".md", "")] = filename
        link_map[f"/{source.replace('.md', '')}"] = filename

        # Also map by slug
        slug = f.get("slug", "")
        if slug:
            link_map[slug] = filename
            link_map[f"/{slug}"] = filename

    return link_map


def rewrite_links(
    content: str, file_info: dict, link_map: dict, all_files: list
) -> tuple:
    """Rewrite internal links and return (content, broken_links)."""
    broken_links = []

    def replace_link(match):
        text = match.group(1)
        target = match.group(2)

        # Skip external links
        if target.startswith(("http://", "https://", "mailto:")):
            return match.group(0)

        # Skip anchors
        if target.startswith("#"):
            return match.group(0)

        # Try to resolve the link
        clean_target = target.split("#")[0]  # Remove anchor

        if clean_target in link_map:
            new_filename = link_map[clean_target]
            anchor = "#" + target.split("#")[1] if "#" in target else ""
            return f"[{text}](./{new_filename}{anchor})"

        # Try resolving relative to source file
        source_dir = os.path.dirname(file_info["source_path"])
        resolved = os.path.normpath(os.path.join(source_dir, clean_target))

        if resolved in link_map:
            new_filename = link_map[resolved]
            anchor = "#" + target.split("#")[1] if "#" in target else ""
            return f"[{text}](./{new_filename}{anchor})"

        # Link not found
        broken_links.append(target)
        return match.group(0)

    # Match markdown links [text](target)
    new_content = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", replace_link, content)

    return new_content, broken_links


def extract_internal_links(links: list) -> list:
    """Extract internal links from analysis."""
    internal = []
    for link in links:
        target = link.get("target", "")
        if not target.startswith(("http://", "https://", "mailto:", "#")):
            internal.append(link)
    return internal


def add_see_also(content: str, file_info: dict, link_map: dict) -> str:
    """Add See Also section if not present."""
    if "## See Also" in content:
        return content

    links = file_info.get("analysis", {}).get("links", [])
    internal_links = extract_internal_links(links)

    see_also_links = []

    for link in internal_links[:5]:  # Limit to 5 links
        target = link["target"]
        text = link["text"]

        # Try to resolve the link
        clean_target = target.split("#")[0]
        if clean_target in link_map:
            new_filename = link_map[clean_target]
            see_also_links.append(f"- [{text}](./{new_filename})")

    if not see_also_links:
        see_also_links.append("- [Documentation Overview](./COMPASS.md)")

    see_also_section = "\n\n## See Also\n\n" + "\n".join(see_also_links) + "\n"

    return content.rstrip() + see_also_section


def read_source_file(source_dir: str, source_path: str) -> str | None:
    """Read the source markdown file."""
    full_path = os.path.join(source_dir, source_path)
    try:
        with open(full_path, "r") as f:
            return f.read()
    except FileNotFoundError:
        return None


def transform_file(
    file_info: dict, source_dir: str, link_map: dict, all_files: list
) -> tuple:
    """Transform a single file. Returns (transformed_content, broken_links, error)."""
    try:
        # Read source file
        content = read_source_file(source_dir, file_info["source_path"])
        if content is None:
            return None, [], f"Source file not found: {file_info['source_path']}"

        title = file_info["analysis"]["title"]
        category = file_info["analysis"]["category"]
        first_paragraph = file_info["analysis"].get("first_paragraph", "")

        # Step 4.1: Fix headings
        content = fix_headings(content, title)

        # Step 4.2: Generate frontmatter
        tags = extract_tags(content, category, title)
        frontmatter = generate_frontmatter(file_info, tags)

        # Step 4.3: Add context block
        content = add_context_block(content, first_paragraph)

        # Step 4.4: Rewrite links
        content, broken_links = rewrite_links(content, file_info, link_map, all_files)

        # Step 4.5: Add See Also
        content = add_see_also(content, file_info, link_map)

        # Step 4.6: Assemble final content
        final_content = frontmatter + "\n" + content

        return final_content, broken_links, None

    except Exception as e:
        return None, [], str(e)


def main():
    manifest_path = "/home/lewis/src/meal-planner/docs/dagger/_indexed/manifest.json"
    source_dir = "/home/lewis/src/meal-planner/docs/dagger"
    output_dir = "/home/lewis/src/meal-planner/docs/dagger/_indexed/docs"

    # Load manifest
    print("Loading manifest...")
    manifest = load_manifest(manifest_path)
    files = manifest.get("files", [])

    print(f"Found {len(files)} files to transform")

    # Build link map
    link_map = build_link_map(files)

    # Process files
    success_count = 0
    error_count = 0
    all_broken_links = {}
    errors = []

    for i, file_info in enumerate(files):
        filename = file_info["filename"]

        # Transform file
        content, broken_links, error = transform_file(
            file_info, source_dir, link_map, files
        )

        if error:
            error_count += 1
            errors.append({"file": filename, "error": error})
            print(f"  ERROR [{i + 1}/{len(files)}]: {filename} - {error}")
            continue

        # Write output file
        output_path = os.path.join(output_dir, filename)
        try:
            with open(output_path, "w") as f:
                f.write(content)
            success_count += 1

            if broken_links:
                all_broken_links[filename] = broken_links

            if (i + 1) % 20 == 0:
                print(f"  Progress: {i + 1}/{len(files)} files processed")

        except Exception as e:
            error_count += 1
            errors.append({"file": filename, "error": str(e)})
            print(f"  ERROR [{i + 1}/{len(files)}]: {filename} - {str(e)}")

    # Update manifest with transform status
    manifest["transform_status"] = {
        "completed_at": datetime.now().isoformat(),
        "success_count": success_count,
        "error_count": error_count,
        "broken_links": all_broken_links,
        "errors": errors,
    }

    # Write updated manifest
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)

    # Print summary
    print(f"\nTRANSFORM: {success_count}/{len(files)} files ({error_count} errors)")

    if all_broken_links:
        total_broken = sum(len(links) for links in all_broken_links.values())
        print(
            f"  Broken links found: {total_broken} across {len(all_broken_links)} files"
        )

    if errors:
        print(f"\nErrors encountered:")
        for err in errors[:10]:  # Show first 10 errors
            print(f"  - {err['file']}: {err['error']}")
        if len(errors) > 10:
            print(f"  ... and {len(errors) - 10} more errors")

    return success_count, len(files), error_count


if __name__ == "__main__":
    main()
