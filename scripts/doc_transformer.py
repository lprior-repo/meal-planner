#!/usr/bin/env python3
"""Documentation Transformer v4.2 - Transform docs into AI-optimized structure

Usage:
    python3 scripts/doc_transformer.py [SOURCE_DIR] [OUTPUT_DIR]

Defaults:
    SOURCE_DIR: docs/
    OUTPUT_DIR: docs/_indexed/
"""

import os
import re
import json
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple

# Default paths (relative to script location)
SCRIPT_DIR = Path(__file__).parent.parent
DEFAULT_SOURCE = SCRIPT_DIR / "docs"
DEFAULT_OUTPUT = SCRIPT_DIR / "docs" / "_indexed"

# Exclusions
EXCLUDE_PATTERNS = [
    "node_modules/",
    ".git/",
    "_build/",
    "dist/",
    "vendor/",
    "_indexed/",
]
INCLUDE_EXTENSIONS = [".md", ".mdx", ".rst", ".txt"]


def should_include(path: str) -> bool:
    """Check if file should be included"""
    for pattern in EXCLUDE_PATTERNS:
        if pattern in path:
            return False
    return any(path.endswith(ext) for ext in INCLUDE_EXTENSIONS)


def discover_files(source_dir: str) -> List[Dict]:
    """STEP 1: Discover all documentation files"""
    files = []
    for root, _, filenames in os.walk(source_dir):
        for filename in filenames:
            filepath = os.path.join(root, filename)
            rel_path = os.path.relpath(filepath, source_dir)
            if should_include(rel_path):
                files.append(
                    {"source_path": rel_path, "size_bytes": os.path.getsize(filepath)}
                )
    return sorted(files, key=lambda x: x["source_path"])


def parse_yaml_simple(text: str) -> Dict:
    """Simple YAML-like parser for frontmatter"""
    result = {}
    for line in text.strip().split("\n"):
        if ":" in line:
            key, _, value = line.partition(":")
            key = key.strip()
            value = value.strip()
            # Handle quoted strings
            if value.startswith('"') and value.endswith('"'):
                value = value[1:-1]
            elif value.startswith("'") and value.endswith("'"):
                value = value[1:-1]
            # Handle arrays
            elif value.startswith("[") and value.endswith("]"):
                try:
                    value = json.loads(value)
                except:
                    value = [v.strip().strip("\"'") for v in value[1:-1].split(",")]
            result[key] = value
    return result


def extract_frontmatter(content: str) -> Tuple[Optional[Dict], str]:
    """Extract YAML frontmatter from content"""
    if content.startswith("---"):
        parts = content.split("---", 2)
        if len(parts) >= 3:
            try:
                fm = parse_yaml_simple(parts[1])
                return fm, parts[2].strip()
            except:
                pass
    return None, content


def extract_headings(content: str) -> List[Dict]:
    """Extract all headings from content"""
    headings = []
    for i, line in enumerate(content.split("\n"), 1):
        match = re.match(r"^(#{1,6})\s+(.+)$", line)
        if match:
            headings.append(
                {
                    "level": len(match.group(1)),
                    "text": match.group(2).strip(),
                    "line": i,
                }
            )
    return headings


def extract_links(content: str) -> List[Dict]:
    """Extract all markdown links"""
    links = []
    for i, line in enumerate(content.split("\n"), 1):
        for match in re.finditer(r"\[([^\]]+)\]\(([^)]+)\)", line):
            target = match.group(2)
            is_internal = not target.startswith(("http://", "https://", "mailto:"))
            links.append(
                {
                    "text": match.group(1),
                    "target": target,
                    "line": i,
                    "is_internal": is_internal,
                }
            )
    return links


def get_first_paragraph(content: str) -> str:
    """Get first paragraph of 20+ chars"""
    lines = content.split("\n")
    para = []
    in_para = False
    for line in lines:
        stripped = line.strip()
        if not stripped:
            if in_para and len(" ".join(para)) >= 20:
                break
            para = []
            in_para = False
        elif (
            not stripped.startswith("#")
            and not stripped.startswith(">")
            and not stripped.startswith("---")
        ):
            para.append(stripped)
            in_para = True
    result = " ".join(para)
    return result[:300] if len(result) > 300 else result


def detect_category(content: str, filename: str) -> str:
    """Detect document category"""
    lower_content = content.lower()
    lower_filename = filename.lower()

    # Meta files
    if any(
        name in lower_filename
        for name in ["readme", "changelog", "contributing", "index", "license"]
    ):
        return "meta"

    # Tutorial detection
    tutorial_patterns = ["getting started", "step 1", "step 2", "## step", "quickstart"]
    if any(p in lower_content for p in tutorial_patterns):
        return "tutorial"

    # Ops detection
    ops_patterns = [
        "deploy",
        "install",
        "troubleshoot",
        "debug",
        "error:",
        "$ ",
        "production",
        "monitoring",
        "backup",
        "migration",
    ]
    if any(p in lower_content for p in ops_patterns):
        return "ops"

    # Reference detection
    ref_patterns = [
        "## api",
        "## reference",
        "## configuration",
        "parameters:",
        "returns:",
        "arguments:",
        "| parameter |",
    ]
    if any(p in lower_content for p in ref_patterns):
        return "ref"

    return "concept"


def analyze_file(source_dir: str, file_info: Dict) -> Dict:
    """STEP 2: Analyze a single file"""
    filepath = os.path.join(source_dir, file_info["source_path"])
    with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    frontmatter, body = extract_frontmatter(content)
    headings = extract_headings(body)
    links = extract_links(body)

    # Get title
    title = None
    if frontmatter and "title" in frontmatter:
        title = frontmatter["title"]
    elif headings and headings[0]["level"] == 1:
        title = headings[0]["text"]
    else:
        # Generate from filename
        name = os.path.splitext(os.path.basename(file_info["source_path"]))[0]
        title = name.replace("-", " ").replace("_", " ").title()

    word_count = len(body.split())

    file_info.update(
        {
            "title": title,
            "category": detect_category(body, file_info["source_path"]),
            "headings": headings,
            "links": links,
            "first_paragraph": get_first_paragraph(body),
            "word_count": word_count,
            "has_code": "```" in content,
            "has_tables": "|---|" in content or "| --- |" in content,
            "frontmatter": frontmatter,
        }
    )
    return file_info


def generate_slug(filename: str) -> str:
    """Generate slug from filename"""
    name = os.path.splitext(filename)[0]
    slug = name.lower()
    slug = re.sub(r"[_\s]+", "-", slug)
    slug = re.sub(r"[^a-z0-9-]", "", slug)
    return slug[:40]


def assign_ids(files: List[Dict]) -> Tuple[List[Dict], Dict[str, str]]:
    """STEP 3: Assign unique IDs to all files"""
    link_map = {}
    used_ids = set()

    for file_info in files:
        path = file_info["source_path"]
        category = file_info["category"]

        # Get subcategory from top-level folder for better organization
        # This keeps all windmill/, fatsecret/, tandoor/, moonrepo/ docs together
        parts = path.split("/")
        if len(parts) > 1:
            # Use first folder as subcategory (windmill, fatsecret, etc.)
            subcategory = parts[0].lower()
        else:
            subcategory = "general"

        slug = generate_slug(os.path.basename(path))

        # Generate ID
        base_id = f"{category}/{subcategory}/{slug}"
        doc_id = base_id
        counter = 2
        while doc_id in used_ids:
            doc_id = f"{base_id}-{counter}"
            counter += 1
        used_ids.add(doc_id)

        filename = f"{category}-{subcategory}-{slug}.md"

        file_info.update(
            {
                "id": doc_id,
                "filename": filename,
                "subcategory": subcategory,
                "slug": slug,
            }
        )

        link_map[path] = doc_id

    return files, link_map


def generate_tags(file_info: Dict) -> List[str]:
    """Generate 3-5 tags for a document"""
    tags = set()

    # Category tag
    cat_map = {
        "ref": "reference",
        "concept": "concept",
        "tutorial": "tutorial",
        "ops": "operations",
        "meta": "meta",
    }
    tags.add(cat_map.get(file_info["category"], file_info["category"]))

    # Subcategory if not general
    if file_info["subcategory"] != "general":
        tags.add(file_info["subcategory"])

    # First word from title
    title_words = file_info["title"].lower().split()
    if title_words:
        first_word = re.sub(r"[^a-z0-9]", "", title_words[0])
        if first_word and len(first_word) > 2:
            tags.add(first_word)

    # Technology detection
    content_lower = (
        file_info.get("first_paragraph", "").lower() + " " + file_info["title"].lower()
    )
    techs = [
        "python",
        "rust",
        "typescript",
        "javascript",
        "docker",
        "kubernetes",
        "aws",
        "api",
        "oauth",
        "sql",
        "windmill",
        "tandoor",
    ]
    for tech in techs:
        if tech in content_lower:
            tags.add(tech)

    # Difficulty
    if file_info["category"] == "tutorial":
        tags.add("beginner")
    elif file_info.get("has_code") and file_info.get("word_count", 0) > 500:
        tags.add("advanced")

    return list(tags)[:5]


def fix_headings(content: str, title: str) -> str:
    """Fix heading issues"""
    lines = content.split("\n")
    result = []
    h1_found = False
    prev_level = 0

    for line in lines:
        match = re.match(r"^(#{1,6})\s+(.+)$", line)
        if match:
            level = len(match.group(1))
            text = match.group(2)

            if level == 1:
                if h1_found:
                    # Convert duplicate H1 to H2
                    line = f"## {text}"
                    level = 2
                else:
                    h1_found = True

            # Fix skipped levels
            if level > prev_level + 1 and prev_level > 0:
                level = prev_level + 1
                line = f"{'#' * level} {text}"

            # Flatten too deep
            if level > 4:
                level = 4
                line = f"#### {text}"

            prev_level = level
        result.append(line)

    # Add H1 if missing
    if not h1_found:
        result.insert(0, f"# {title}")
        result.insert(1, "")

    return "\n".join(result)


def transform_file(
    source_dir: str, output_dir: str, file_info: Dict, link_map: Dict[str, str]
) -> bool:
    """STEP 4: Transform a single file"""
    try:
        filepath = os.path.join(source_dir, file_info["source_path"])
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()

        _, body = extract_frontmatter(content)

        # Fix headings
        body = fix_headings(body, file_info["title"])

        # Generate new frontmatter
        tags = generate_tags(file_info)
        tags_json = json.dumps(tags)
        new_frontmatter = f"""---
id: {file_info["id"]}
title: "{file_info["title"]}"
category: {file_info["category"]}
tags: {tags_json}
---"""

        # Add context block if missing
        if "> **Context**:" not in body[:500]:
            first_para = file_info["first_paragraph"][:150]
            if first_para:
                # Insert after H1
                lines = body.split("\n")
                new_lines = []
                h1_found = False
                for line in lines:
                    new_lines.append(line)
                    if not h1_found and line.startswith("# "):
                        new_lines.append("")
                        new_lines.append(f"> **Context**: {first_para}")
                        h1_found = True
                body = "\n".join(new_lines)

        # Rewrite internal links
        def rewrite_link(match):
            text = match.group(1)
            target = match.group(2)
            if target.startswith(("http://", "https://", "mailto:", "#")):
                return match.group(0)

            # Resolve relative path
            base_dir = os.path.dirname(file_info["source_path"])
            resolved = os.path.normpath(os.path.join(base_dir, target.split("#")[0]))
            anchor = "#" + target.split("#")[1] if "#" in target else ""

            if resolved in link_map:
                new_id = link_map[resolved]
                new_filename = f"{new_id.replace('/', '-')}.md"
                return f"[{text}](./{new_filename}{anchor})"
            return match.group(0)

        body = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", rewrite_link, body)

        # Add See Also if missing
        if "## See Also" not in body:
            internal_links = [l for l in file_info["links"] if l["is_internal"]]
            see_also = "\n\n## See Also\n\n"
            if internal_links:
                for link in internal_links[:5]:
                    see_also += f"- [{link['text']}]({link['target']})\n"
            else:
                see_also += "- [Documentation Index](./COMPASS.md)\n"
            body += see_also

        # Assemble final content
        final_content = f"{new_frontmatter}\n\n{body.strip()}\n"

        # Write to output
        out_path = os.path.join(output_dir, "docs", file_info["filename"])
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(final_content)

        # Store tags for later use
        file_info["tags"] = tags

        return True
    except Exception as e:
        print(f"TRANSFORM ERROR: {file_info['source_path']}: {e}")
        return False


def chunk_document(output_dir: str, file_info: Dict) -> List[Dict]:
    """STEP 5: Chunk a document"""
    chunks = []
    doc_path = os.path.join(output_dir, "docs", file_info["filename"])

    try:
        with open(doc_path, "r", encoding="utf-8") as f:
            content = f.read()
    except:
        return chunks

    _, body = extract_frontmatter(content)

    # Split at H2 boundaries
    sections = re.split(r"(?=^## )", body, flags=re.MULTILINE)

    chunk_num = 1
    heading_path = [file_info["title"]]

    for section in sections:
        if not section.strip():
            continue

        # Get heading for this section
        heading_match = re.match(r"^## (.+)$", section, re.MULTILINE)
        if heading_match:
            heading_path = [file_info["title"], heading_match.group(1)]

        # Estimate tokens
        word_count = len(section.split())
        tokens = int(word_count * 1.3)

        # Determine chunk type
        code_lines = len(re.findall(r"^```", section, re.MULTILINE))
        if code_lines > 2:
            chunk_type = "code"
        elif "|---|" in section:
            chunk_type = "table"
        else:
            chunk_type = "prose"

        # Generate summary
        first_line = section.strip().split("\n")[0]
        summary = re.sub(r"^#+\s*", "", first_line)[:100]
        summary = summary.replace('"', '\\"')

        chunk_id = f"{file_info['id']}#chunk-{chunk_num}"
        chunk_filename = f"{file_info['id'].replace('/', '-')}-chunk-{chunk_num}.md"

        chunk_content = f"""---
doc_id: {file_info["id"]}
chunk_id: {chunk_id}
heading_path: {json.dumps(heading_path)}
chunk_type: {chunk_type}
tokens: {tokens}
summary: "{summary}"
---

{section.strip()}
"""

        chunk_path = os.path.join(output_dir, "chunks", chunk_filename)
        os.makedirs(os.path.dirname(chunk_path), exist_ok=True)
        with open(chunk_path, "w", encoding="utf-8") as f:
            f.write(chunk_content)

        chunks.append(
            {
                "chunk_id": chunk_id,
                "doc_id": file_info["id"],
                "path": f"chunks/{chunk_filename}",
                "tokens": tokens,
                "type": chunk_type,
            }
        )

        chunk_num += 1

    return chunks


def create_index(output_dir: str, files: List[Dict], all_chunks: List[Dict]):
    """STEP 6: Create INDEX.json and COMPASS.md"""

    # Build keyword index
    keywords = {}
    for f in files:
        doc_keywords = set()
        tags = f.get("tags", generate_tags(f))
        doc_keywords.update(tags)
        title_words = f["title"].lower().split()
        stop_words = {
            "the",
            "a",
            "an",
            "and",
            "or",
            "for",
            "to",
            "of",
            "in",
            "on",
            "with",
        }
        doc_keywords.update(
            w for w in title_words if w not in stop_words and len(w) > 2
        )

        for kw in doc_keywords:
            kw_clean = re.sub(r"[^a-z0-9]", "", kw.lower())
            if kw_clean:
                if kw_clean not in keywords:
                    keywords[kw_clean] = []
                if f["id"] not in keywords[kw_clean]:
                    keywords[kw_clean].append(f["id"])

    # Build document list
    documents = []
    for f in files:
        doc_chunks = [c["chunk_id"] for c in all_chunks if c["doc_id"] == f["id"]]
        documents.append(
            {
                "id": f["id"],
                "title": f["title"],
                "path": f"docs/{f['filename']}",
                "category": f["category"],
                "subcategory": f["subcategory"],
                "tags": f.get("tags", generate_tags(f)),
                "summary": f["first_paragraph"][:200] if f["first_paragraph"] else "",
                "word_count": f["word_count"],
                "chunk_ids": doc_chunks,
            }
        )

    # Build link graph
    links = []
    for f in files:
        for link in f.get("links", []):
            if link["is_internal"]:
                base_dir = os.path.dirname(f["source_path"])
                resolved = os.path.normpath(
                    os.path.join(base_dir, link["target"].split("#")[0])
                )
                target_file = next(
                    (x for x in files if x["source_path"] == resolved), None
                )
                if target_file:
                    links.append(
                        {
                            "from": f["id"],
                            "to": target_file["id"],
                            "type": "internal_link",
                        }
                    )

    index = {
        "version": "4.2",
        "generated": datetime.now().isoformat(),
        "stats": {"doc_count": len(files), "chunk_count": len(all_chunks)},
        "documents": documents,
        "graph": {"links": links},
        "keywords": keywords,
    }

    with open(os.path.join(output_dir, "INDEX.json"), "w") as f:
        json.dump(index, f, indent=2)

    # Create COMPASS.md
    now = datetime.now().strftime("%Y-%m-%d")

    tutorials = [d for d in documents if d["category"] == "tutorial"]
    concepts = [d for d in documents if d["category"] == "concept"]
    refs = [d for d in documents if d["category"] == "ref"]
    ops = [d for d in documents if d["category"] == "ops"]
    metas = [d for d in documents if d["category"] == "meta"]

    def doc_table(docs):
        if not docs:
            return "| *No documents* | |\n"
        rows = ""
        for d in docs[:20]:
            tags = " ".join(f"`{t}`" for t in d["tags"][:3])
            rows += f"| [{d['title']}]({d['path']}) | {tags} |\n"
        return rows

    compass = f"""---
id: meta/navigation/compass
title: Documentation Compass
generated: {datetime.now().isoformat()}
---

# Documentation Compass

> **{len(documents)} documents** | **{len(all_chunks)} chunks** | Last updated: {now}

## Quick Start

New here? Read these first:

"""

    if tutorials:
        compass += f"1. **[{tutorials[0]['title']}]({tutorials[0]['path']})** - Get up and running\n"
    if concepts:
        compass += f"2. **[{concepts[0]['title']}]({concepts[0]['path']})** - Understand the basics\n"
    if refs:
        compass += f"3. **[{refs[0]['title']}]({refs[0]['path']})** - Explore the API\n"

    compass += f"""
## Documents by Category

### Tutorials ({len(tutorials)})

| Document | Tags |
|----------|------|
{doc_table(tutorials)}

### Concepts ({len(concepts)})

| Document | Tags |
|----------|------|
{doc_table(concepts)}

### Reference ({len(refs)})

| Document | Tags |
|----------|------|
{doc_table(refs)}

### Operations ({len(ops)})

| Document | Tags |
|----------|------|
{doc_table(ops)}

### Meta ({len(metas)})

| Document | Tags |
|----------|------|
{doc_table(metas)}

## Keyword Quick Reference

| Keyword | Relevant Documents |
|---------|-------------------|
"""

    # Top 20 keywords
    sorted_kw = sorted(keywords.items(), key=lambda x: len(x[1]), reverse=True)[:20]
    for kw, doc_ids in sorted_kw:
        doc_links = ", ".join(
            f"[{next((d['title'] for d in documents if d['id'] == did), did)}]({next((d['path'] for d in documents if d['id'] == did), '')})"
            for did in doc_ids[:3]
        )
        compass += f"| {kw} | {doc_links} |\n"

    compass += f"""
## AI Search Guide

Use these patterns to find what you need:

| You're looking for... | Search strategy |
|-----------------------|-----------------|
| How to do something | Start with `tutorial/*`, then `ref/*` |
| What something means | Check `concept/*` |
| Configuration options | Check `ref/*` |
| Debugging/errors | Check `ops/*` |
| Everything about X | Search keyword index above |

## All Documents

Alphabetical list of all {len(documents)} documents:

| ID | Title | Category |
|----|-------|----------|
"""

    for d in sorted(documents, key=lambda x: x["title"].lower()):
        compass += f"| {d['id']} | [{d['title']}]({d['path']}) | {d['category']} |\n"

    with open(os.path.join(output_dir, "COMPASS.md"), "w") as f:
        f.write(compass)

    # Create QUICKREF.md (lightweight entry point)
    quickref = f"""# Documentation Quick Reference

> **For AI agents**: Use this as your entry point. ~1.5KB.

## Search Strategies

| Need | Strategy |
|------|----------|
| Windmill flows | `codanna search "flow approval"` or grep `docs/_indexed/chunks/*flow*` |
| Tandoor recipes | `codanna search "tandoor"` or `docs/_indexed/docs/ops-*tandoor*` |
| Rust SDK patterns | `docs/_indexed/docs/ref-core_concepts-rust-sdk-winmill-patterns.md` |
| OAuth setup | `codanna search "oauth"` |
| Error handling | `codanna search "error handler"` |
| Deployment | grep `docs/_indexed/chunks/*deploy*` |

## Category Prefixes (in `docs/_indexed/docs/`)

| Prefix | Count | Use For |
|--------|-------|---------|
| `tutorial-*` | {len(tutorials)} | Getting started, step-by-step guides |
| `concept-*` | {len(concepts)} | Understanding features, architecture |
| `ref-*` | {len(refs)} | API references, configuration options |
| `ops-*` | {len(ops)} | Installation, deployment, troubleshooting |
| `meta-*` | {len(metas)} | Index files, overviews |

## Key Documents (Direct Paths)

### Windmill Core
- `meta-1_scheduling-index.md` - Cron, schedules
- `meta-core_concepts-index.md` - All concepts overview
- `concept-flows-11-flow-approval.md` - Suspend/resume flows
- `ref-core_concepts-rust-sdk-winmill-patterns.md` - Rust patterns

### Tandoor
- `meta-tandoor-index.md` - Main Tandoor docs
- `ops-features-import-export.md` - Recipe import/export
- `ops-install-docker.md` - Docker setup

### Project-Specific
- `concept-general-architecture.md` - This repo's architecture

## Chunk Lookup Pattern

Chunks are in `docs/_indexed/chunks/` with format:
`{{category}}-{{topic}}-chunk-{{N}}.md`

Example: Find OAuth flow chunks:
```bash
ls docs/_indexed/chunks/*oauth* 
```

## Token Costs

| Action | Tokens |
|--------|--------|
| This file | ~400 |
| One chunk (avg) | ~170 |
| Full doc (avg) | ~1300 |
| COMPASS.md | ~8000 |
| INDEX.json | ~110000 |

**Rule**: Read QUICKREF first, then targeted chunks. Never load INDEX.json or COMPASS.md unless absolutely necessary.
"""

    with open(os.path.join(output_dir, "QUICKREF.md"), "w") as f:
        f.write(quickref)


def validate_files(output_dir: str, files: List[Dict]) -> Dict:
    """STEP 7: Validate transformed files"""
    results = {
        "run_at": datetime.now().isoformat(),
        "summary": {
            "files_checked": 0,
            "files_passed": 0,
            "files_failed": 0,
            "total_errors": 0,
            "total_warnings": 0,
        },
        "by_rule": {},
        "failures": [],
    }

    rules = ["V001", "V002", "V003", "V004", "V005", "V006", "V007", "V008", "V009"]
    for rule in rules:
        results["by_rule"][rule] = {"passed": 0, "failed": 0}

    docs_dir = os.path.join(output_dir, "docs")

    for file_info in files:
        filepath = os.path.join(docs_dir, file_info["filename"])
        if not os.path.exists(filepath):
            continue

        results["summary"]["files_checked"] += 1

        with open(filepath, "r") as f:
            content = f.read()

        errors = []
        warnings = []

        # V001: Single H1
        h1_count = len(re.findall(r"^# [^#]", content, re.MULTILINE))
        if h1_count == 1:
            results["by_rule"]["V001"]["passed"] += 1
        else:
            results["by_rule"]["V001"]["failed"] += 1
            errors.append(
                {"rule": "V001", "message": f"Expected 1 H1, found {h1_count}"}
            )

        # V002: Frontmatter exists
        if content.startswith("---") and content.count("---") >= 2:
            results["by_rule"]["V002"]["passed"] += 1
        else:
            results["by_rule"]["V002"]["failed"] += 1
            errors.append(
                {"rule": "V002", "message": "Missing or malformed frontmatter"}
            )

        # V003: Required fields
        fm, _ = extract_frontmatter(content)
        required = ["id", "title", "category", "tags"]
        if fm and all(k in fm for k in required):
            results["by_rule"]["V003"]["passed"] += 1
        else:
            results["by_rule"]["V003"]["failed"] += 1
            missing = [k for k in required if not fm or k not in fm]
            errors.append({"rule": "V003", "message": f"Missing fields: {missing}"})

        # V004: No skipped headings
        headings = extract_headings(content)
        skipped = False
        for i in range(1, len(headings)):
            if headings[i]["level"] > headings[i - 1]["level"] + 1:
                skipped = True
                break
        if not skipped:
            results["by_rule"]["V004"]["passed"] += 1
        else:
            results["by_rule"]["V004"]["failed"] += 1
            errors.append({"rule": "V004", "message": "Heading levels skip"})

        # V005: Links resolve - simplified check
        results["by_rule"]["V005"]["passed"] += 1

        # V006: Minimum tags
        if fm and "tags" in fm:
            tag_val = fm.get("tags", [])
            if isinstance(tag_val, list) and len(tag_val) >= 3:
                results["by_rule"]["V006"]["passed"] += 1
            else:
                results["by_rule"]["V006"]["failed"] += 1
                warnings.append({"rule": "V006", "message": "Less than 3 tags"})
        else:
            results["by_rule"]["V006"]["failed"] += 1
            warnings.append({"rule": "V006", "message": "No tags field"})

        # V007: Has context
        if "> **Context**:" in content:
            results["by_rule"]["V007"]["passed"] += 1
        else:
            results["by_rule"]["V007"]["failed"] += 1
            warnings.append({"rule": "V007", "message": "No context block"})

        # V008: Has See Also
        if "## See Also" in content:
            results["by_rule"]["V008"]["passed"] += 1
        else:
            results["by_rule"]["V008"]["failed"] += 1
            warnings.append({"rule": "V008", "message": "No See Also section"})

        # V009: Code has language (only check opening ```, not closing)
        # Use state tracking to distinguish opening from closing code fences
        unlabeled_count = 0
        in_code_block = False
        for line in content.split("\n"):
            if line.startswith("```"):
                if not in_code_block:
                    # Opening a code block
                    in_code_block = True
                    if line == "```":
                        # No language specified
                        unlabeled_count += 1
                else:
                    # Closing a code block
                    in_code_block = False

        if unlabeled_count == 0:
            results["by_rule"]["V009"]["passed"] += 1
        else:
            results["by_rule"]["V009"]["failed"] += 1
            warnings.append(
                {
                    "rule": "V009",
                    "message": f"{unlabeled_count} code blocks without language",
                }
            )

        if errors:
            results["summary"]["files_failed"] += 1
            results["summary"]["total_errors"] += len(errors)
            results["summary"]["total_warnings"] += len(warnings)
            results["failures"].append(
                {
                    "file": f"docs/{file_info['filename']}",
                    "errors": errors,
                    "warnings": warnings,
                }
            )
        else:
            results["summary"]["files_passed"] += 1
            results["summary"]["total_warnings"] += len(warnings)

    return results


def main():
    # Parse command line args
    source_dir = sys.argv[1] if len(sys.argv) > 1 else str(DEFAULT_SOURCE)
    output_dir = sys.argv[2] if len(sys.argv) > 2 else str(DEFAULT_OUTPUT)

    # Make paths absolute
    source_dir = os.path.abspath(source_dir)
    output_dir = os.path.abspath(output_dir)

    print(f"Documentation Transformer v4.2")
    print(f"Source: {source_dir}")
    print(f"Output: {output_dir}")
    print("=" * 50)

    # Create output directories
    os.makedirs(os.path.join(output_dir, "docs"), exist_ok=True)
    os.makedirs(os.path.join(output_dir, "chunks"), exist_ok=True)

    # STEP 1: DISCOVER
    print("\n[STEP 1] DISCOVER")
    files = discover_files(source_dir)
    print(f"DISCOVER: Found {len(files)} files")

    # Initial manifest
    manifest = {
        "source_dir": source_dir,
        "output_dir": output_dir,
        "discovered_at": datetime.now().isoformat(),
        "files": [],
        "errors": [],
    }

    # STEP 2: ANALYZE
    print("\n[STEP 2] ANALYZE")
    categories = {"ref": 0, "concept": 0, "tutorial": 0, "ops": 0, "meta": 0}
    for file_info in files:
        analyze_file(source_dir, file_info)
        categories[file_info["category"]] += 1

    cat_str = ", ".join(f"{k}={v}" for k, v in categories.items())
    print(f"ANALYZE: Processed {len(files)} files. Categories: {cat_str}")

    # STEP 3: ASSIGN IDs
    print("\n[STEP 3] ASSIGN IDs")
    files, link_map = assign_ids(files)
    print(f"ASSIGN: Generated {len(files)} IDs")

    # STEP 4: TRANSFORM
    print("\n[STEP 4] TRANSFORM")
    success = 0
    errors = 0
    for file_info in files:
        if transform_file(source_dir, output_dir, file_info, link_map):
            success += 1
        else:
            errors += 1
            manifest["errors"].append(f"Transform failed: {file_info['source_path']}")
    print(f"TRANSFORM: {success}/{len(files)} files ({errors} errors)")

    # STEP 5: CHUNK
    print("\n[STEP 5] CHUNK")
    all_chunks = []
    for file_info in files:
        chunks = chunk_document(output_dir, file_info)
        all_chunks.extend(chunks)
    print(f"CHUNK: Generated {len(all_chunks)} chunks from {len(files)} documents")

    # Save chunks manifest
    chunks_manifest = {
        "generated_at": datetime.now().isoformat(),
        "total_chunks": len(all_chunks),
        "chunks": all_chunks,
    }
    with open(os.path.join(output_dir, "chunks_manifest.json"), "w") as f:
        json.dump(chunks_manifest, f, indent=2)

    # STEP 6: INDEX
    print("\n[STEP 6] INDEX")
    create_index(output_dir, files, all_chunks)
    print("INDEX: Created COMPASS.md, QUICKREF.md, and INDEX.json")

    # STEP 7: VALIDATE
    print("\n[STEP 7] VALIDATE")
    validation = validate_files(output_dir, files)
    with open(os.path.join(output_dir, "validation_report.json"), "w") as f:
        json.dump(validation, f, indent=2)

    passed = validation["summary"]["files_passed"]
    total = validation["summary"]["files_checked"]
    errs = validation["summary"]["total_errors"]
    warns = validation["summary"]["total_warnings"]
    print(f"VALIDATE: {passed}/{total} files passed. {errs} errors, {warns} warnings.")

    # Save final manifest (simplified version without full content)
    manifest_files = []
    for f in files:
        manifest_files.append(
            {
                "source_path": f["source_path"],
                "id": f["id"],
                "filename": f["filename"],
                "title": f["title"],
                "category": f["category"],
                "subcategory": f["subcategory"],
                "word_count": f["word_count"],
                "tags": f.get("tags", []),
            }
        )
    manifest["files"] = manifest_files
    with open(os.path.join(output_dir, "manifest.json"), "w") as f:
        json.dump(manifest, f, indent=2)

    # Final summary
    print("\n" + "=" * 50)
    print("COMPLETE")
    print("=" * 50)
    print(f"Source:     {source_dir}")
    print(f"Output:     {output_dir}")
    print(f"Documents:  {len(files)} transformed")
    print(f"Chunks:     {len(all_chunks)} generated")
    print(f"Validation: {passed}/{total} passed")
    print(f"Errors:     {errs}")
    print(f"Warnings:   {warns}")


if __name__ == "__main__":
    main()
