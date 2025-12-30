#!/usr/bin/env python3
"""
Add navigation links to documentation chunks.

Reads chunks_manifest.json and adds "See Also" footers to each chunk
based on shared tags, same parent doc, and keyword overlap.

Usage:
    python scripts/add_chunk_links.py

Run after indexing docs to add navigation links.
"""

import json
import re
from pathlib import Path
from collections import defaultdict

INDEXED_DIR = Path("docs/_indexed")
CHUNKS_DIR = INDEXED_DIR / "chunks"
MANIFEST_PATH = INDEXED_DIR / "chunks_manifest.json"


def load_manifest():
    """Load chunks manifest."""
    with open(MANIFEST_PATH) as f:
        return json.load(f)


def extract_parent_doc(chunk_name: str) -> str:
    """Extract parent doc from chunk name (remove -chunk-N suffix)."""
    return re.sub(r"-chunk-\d+$", "", chunk_name.replace(".md", ""))


def find_related_chunks(chunk: dict, all_chunks: list, tag_index: dict) -> dict:
    """Find related chunks for navigation."""
    chunk_name = chunk["filename"].replace(".md", "")
    parent = extract_parent_doc(chunk_name)
    chunk_tags = set(chunk.get("tags", []))

    related = {
        "same_doc": [],  # Other chunks from same parent doc
        "by_tag": [],  # Chunks sharing tags
    }

    for other in all_chunks:
        other_name = other["filename"].replace(".md", "")
        if other_name == chunk_name:
            continue

        other_parent = extract_parent_doc(other_name)
        other_tags = set(other.get("tags", []))

        # Same parent doc (sequential reading)
        if other_parent == parent:
            related["same_doc"].append(other_name)
            continue

        # Shared tags (topical relation)
        shared = chunk_tags & other_tags
        if len(shared) >= 2:  # At least 2 shared tags
            related["by_tag"].append((other_name, len(shared)))

    # Sort by_tag by relevance (most shared tags first)
    related["by_tag"] = [
        name for name, _ in sorted(related["by_tag"], key=lambda x: -x[1])
    ][:5]

    # Sort same_doc chunks naturally (chunk-1, chunk-2, etc.)
    def chunk_num(name):
        match = re.search(r"-chunk-(\d+)$", name)
        return int(match.group(1)) if match else 0

    related["same_doc"] = sorted(related["same_doc"], key=chunk_num)

    return related


def format_footer(chunk_name: str, related: dict) -> str:
    """Format the See Also footer."""
    lines = ["\n---", "<!-- Navigation (auto-generated) -->"]

    # Same doc navigation (prev/next in sequence)
    if related["same_doc"]:
        chunk_num_match = re.search(r"-chunk-(\d+)$", chunk_name)
        if chunk_num_match:
            current_num = int(chunk_num_match.group(1))
            prev_chunks = [
                c
                for c in related["same_doc"]
                if re.search(r"-chunk-(\d+)$", c)
                and int(re.search(r"-chunk-(\d+)$", c).group(1)) < current_num
            ]
            next_chunks = [
                c
                for c in related["same_doc"]
                if re.search(r"-chunk-(\d+)$", c)
                and int(re.search(r"-chunk-(\d+)$", c).group(1)) > current_num
            ]

            nav = []
            if prev_chunks:
                prev_c = prev_chunks[-1]  # Immediate previous
                nav.append(f"[<< Prev](./{prev_c}.md)")
            if next_chunks:
                next_c = next_chunks[0]  # Immediate next
                nav.append(f"[Next >>](./{next_c}.md)")
            if nav:
                lines.append("**Sequence:** " + " | ".join(nav))

    # Related by tags
    if related["by_tag"]:
        links = [
            f"[{name.split('-')[-2] if 'chunk' in name else name[:30]}](./{name}.md)"
            for name in related["by_tag"][:4]
        ]
        lines.append("**Related:** " + " | ".join(links))

    if len(lines) <= 2:  # Only header, no links
        return ""

    return "\n".join(lines) + "\n"


def has_navigation_footer(content: str) -> bool:
    """Check if chunk already has navigation footer."""
    return "<!-- Navigation (auto-generated) -->" in content


def process_chunks():
    """Add navigation footers to all chunks."""
    manifest = load_manifest()
    chunks = manifest.get("chunks", [])

    if not chunks:
        print("No chunks found in manifest")
        return

    # Build tag index for fast lookup
    tag_index = defaultdict(list)
    for chunk in chunks:
        for tag in chunk.get("tags", []):
            tag_index[tag].append(chunk)

    updated = 0
    skipped = 0

    for chunk in chunks:
        chunk_path = CHUNKS_DIR / chunk["filename"]
        if not chunk_path.exists():
            continue

        content = chunk_path.read_text()

        # Skip if already has footer
        if has_navigation_footer(content):
            skipped += 1
            continue

        # Find related chunks
        chunk_name = chunk["filename"].replace(".md", "")
        related = find_related_chunks(chunk, chunks, tag_index)

        # Generate and append footer
        footer = format_footer(chunk_name, related)
        if footer:
            # Remove any existing trailing newlines and add footer
            content = content.rstrip() + "\n" + footer
            chunk_path.write_text(content)
            updated += 1

    print(f"Updated: {updated} chunks")
    print(f"Skipped: {skipped} chunks (already have navigation)")
    print(f"Total: {len(chunks)} chunks")


if __name__ == "__main__":
    process_chunks()
