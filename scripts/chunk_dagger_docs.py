#!/usr/bin/env python3
"""
DOC_TRANSFORMER Step 5: CHUNK
Create semantic chunks from transformed Dagger documentation.
"""

import json
import os
import re
from datetime import datetime
from pathlib import Path
from dataclasses import dataclass, field
from typing import List, Optional

DOCS_DIR = Path("/home/lewis/src/meal-planner/docs/dagger/_indexed/docs")
CHUNKS_DIR = Path("/home/lewis/src/meal-planner/docs/dagger/_indexed/chunks")
MANIFEST_PATH = Path("/home/lewis/src/meal-planner/docs/dagger/_indexed/manifest.json")

# Thresholds
MAX_TOKENS_BEFORE_H3_SPLIT = 1500
LARGE_CODE_BLOCK_LINES = 50
LARGE_TABLE_ROWS = 10


@dataclass
class Chunk:
    doc_id: str
    chunk_id: str
    heading_path: List[str]
    chunk_type: str
    tokens: int
    summary: str
    content: str


def estimate_tokens(text: str) -> int:
    """Estimate tokens as word_count * 1.3, rounded."""
    word_count = len(text.split())
    return round(word_count * 1.3)


def get_first_sentence(text: str, max_chars: int = 100) -> str:
    """Extract first sentence, truncated to max_chars."""
    # Remove frontmatter if present
    content = re.sub(r"^---\n.*?\n---\n", "", text, flags=re.DOTALL).strip()
    # Remove headings
    content = re.sub(r"^#+\s+.*$", "", content, flags=re.MULTILINE).strip()
    # Get first sentence
    match = re.match(r"^([^.!?]+[.!?])", content)
    if match:
        sentence = match.group(1).strip()
    else:
        sentence = content[:max_chars] if content else "No summary available."

    # Truncate if needed
    if len(sentence) > max_chars:
        sentence = sentence[: max_chars - 3] + "..."
    return sentence


def detect_chunk_type(content: str) -> str:
    """Detect chunk type based on content."""
    lines = content.split("\n")
    total_lines = len(lines)
    if total_lines == 0:
        return "prose"

    # Count code fence lines
    in_code = False
    code_lines = 0
    for line in lines:
        if line.strip().startswith("```"):
            in_code = not in_code
            code_lines += 1
        elif in_code:
            code_lines += 1

    # Count table lines (lines with |)
    table_lines = sum(
        1 for line in lines if "|" in line and line.strip().startswith("|")
    )

    code_ratio = code_lines / total_lines if total_lines > 0 else 0
    table_ratio = table_lines / total_lines if total_lines > 0 else 0

    if code_ratio > 0.5:
        return "code"
    elif table_ratio > 0.5:
        return "table"
    elif code_ratio > 0.2 and table_ratio > 0.1:
        return "mixed"
    elif code_ratio > 0.2:
        return "mixed"
    return "prose"


def split_at_headings(content: str) -> List[tuple]:
    """Split content at H2 headings, returning list of (heading_text, content)."""
    # Pattern to match H2 headings
    h2_pattern = r"^## (.+)$"

    parts = []
    lines = content.split("\n")
    current_heading = None
    current_content = []

    for line in lines:
        h2_match = re.match(h2_pattern, line)
        if h2_match:
            # Save previous section
            if current_content or current_heading:
                parts.append((current_heading, "\n".join(current_content)))
            current_heading = h2_match.group(1).strip()
            current_content = []
        else:
            current_content.append(line)

    # Don't forget the last section
    if current_content or current_heading:
        parts.append((current_heading, "\n".join(current_content)))

    return parts


def split_large_section_at_h3(content: str, h2_heading: str) -> List[tuple]:
    """Split a large section at H3 headings."""
    h3_pattern = r"^### (.+)$"

    parts = []
    lines = content.split("\n")
    current_heading = h2_heading
    current_content = []

    for line in lines:
        h3_match = re.match(h3_pattern, line)
        if h3_match:
            if current_content:
                parts.append((current_heading, "\n".join(current_content)))
            current_heading = f"{h2_heading} > {h3_match.group(1).strip()}"
            current_content = []
        else:
            current_content.append(line)

    if current_content:
        parts.append((current_heading, "\n".join(current_content)))

    return parts


def extract_large_code_blocks(content: str) -> List[tuple]:
    """Extract large code blocks (>50 lines) as separate chunks."""
    code_pattern = r"```[\w]*\n(.*?)```"

    chunks = []
    last_end = 0

    for match in re.finditer(code_pattern, content, re.DOTALL):
        code_content = match.group(1)
        code_lines = code_content.count("\n") + 1

        if code_lines > LARGE_CODE_BLOCK_LINES:
            # Add content before this code block
            before = content[last_end : match.start()].strip()
            if before:
                chunks.append(("prose", before))

            # Add the code block itself
            chunks.append(("code", match.group(0)))
            last_end = match.end()

    # Add remaining content
    remaining = content[last_end:].strip()
    if remaining:
        chunks.append(("prose", remaining))

    return chunks if chunks else [("prose", content)]


def chunk_document(doc_id: str, filename: str) -> List[Chunk]:
    """Create chunks for a single document."""
    doc_path = DOCS_DIR / filename
    if not doc_path.exists():
        return []

    content = doc_path.read_text()

    # Extract frontmatter if present
    frontmatter_match = re.match(r"^---\n(.*?)\n---\n", content, re.DOTALL)
    main_content = content
    if frontmatter_match:
        main_content = content[frontmatter_match.end() :]

    # Get document title from first H1
    title_match = re.match(r"^#\s+(.+)$", main_content, re.MULTILINE)
    doc_title = title_match.group(1).strip() if title_match else doc_id.split("/")[-1]

    chunks = []
    chunk_num = 1

    # First, split at H2 headings
    h2_sections = split_at_headings(main_content)

    for h2_heading, section_content in h2_sections:
        section_tokens = estimate_tokens(section_content)
        heading_path = [doc_title]
        if h2_heading:
            heading_path.append(h2_heading)

        # If section is large, split at H3
        if section_tokens > MAX_TOKENS_BEFORE_H3_SPLIT and h2_heading:
            h3_sections = split_large_section_at_h3(section_content, h2_heading)
            for h3_heading, h3_content in h3_sections:
                if not h3_content.strip():
                    continue

                # Check for large code blocks
                code_parts = extract_large_code_blocks(h3_content)
                for part_type, part_content in code_parts:
                    if not part_content.strip():
                        continue

                    chunk_id = f"{doc_id}#chunk-{chunk_num}"
                    tokens = estimate_tokens(part_content)

                    # Build heading path for H3
                    h_path = [doc_title]
                    if " > " in h3_heading:
                        parts = h3_heading.split(" > ")
                        h_path.extend(parts)
                    else:
                        h_path.append(h3_heading)

                    chunk_type = (
                        part_type
                        if part_type == "code"
                        else detect_chunk_type(part_content)
                    )

                    chunks.append(
                        Chunk(
                            doc_id=doc_id,
                            chunk_id=chunk_id,
                            heading_path=h_path,
                            chunk_type=chunk_type,
                            tokens=tokens,
                            summary=get_first_sentence(part_content),
                            content=part_content,
                        )
                    )
                    chunk_num += 1
        else:
            # Small section - keep as single chunk
            if not section_content.strip():
                continue

            # Still check for large code blocks
            code_parts = extract_large_code_blocks(section_content)
            for part_type, part_content in code_parts:
                if not part_content.strip():
                    continue

                chunk_id = f"{doc_id}#chunk-{chunk_num}"
                tokens = estimate_tokens(part_content)
                chunk_type = (
                    part_type
                    if part_type == "code"
                    else detect_chunk_type(part_content)
                )

                chunks.append(
                    Chunk(
                        doc_id=doc_id,
                        chunk_id=chunk_id,
                        heading_path=heading_path.copy(),
                        chunk_type=chunk_type,
                        tokens=tokens,
                        summary=get_first_sentence(part_content),
                        content=part_content,
                    )
                )
                chunk_num += 1

    # If no chunks were created, create a single chunk for the whole doc
    if not chunks:
        chunk_id = f"{doc_id}#chunk-1"
        tokens = estimate_tokens(main_content)

        chunks.append(
            Chunk(
                doc_id=doc_id,
                chunk_id=chunk_id,
                heading_path=[doc_title],
                chunk_type=detect_chunk_type(main_content),
                tokens=tokens,
                summary=get_first_sentence(main_content),
                content=main_content,
            )
        )

    return chunks


def write_chunk(chunk: Chunk) -> str:
    """Write a chunk to a file and return the filename."""
    # Create filename by replacing / and # with -
    filename = chunk.chunk_id.replace("/", "-").replace("#", "-") + ".md"
    filepath = CHUNKS_DIR / filename

    # Format heading_path as YAML array
    heading_yaml = json.dumps(chunk.heading_path)

    content = f"""---
doc_id: {chunk.doc_id}
chunk_id: {chunk.chunk_id}
heading_path: {heading_yaml}
chunk_type: {chunk.chunk_type}
tokens: {chunk.tokens}
summary: "{chunk.summary.replace('"', '\\"')}"
---
{chunk.content}
"""

    filepath.write_text(content)
    return filename


def main():
    # Ensure chunks directory exists
    CHUNKS_DIR.mkdir(parents=True, exist_ok=True)

    # Load manifest
    with open(MANIFEST_PATH) as f:
        manifest = json.load(f)

    all_chunks = []
    type_counts = {"prose": 0, "code": 0, "table": 0, "mixed": 0}

    for file_info in manifest["files"]:
        doc_id = file_info["id"]
        filename = file_info["filename"]

        chunks = chunk_document(doc_id, filename)

        for chunk in chunks:
            chunk_filename = write_chunk(chunk)
            type_counts[chunk.chunk_type] += 1

            all_chunks.append(
                {
                    "chunk_id": chunk.chunk_id,
                    "doc_id": chunk.doc_id,
                    "path": f"chunks/{chunk_filename}",
                    "tokens": chunk.tokens,
                    "type": chunk.chunk_type,
                }
            )

    # Write chunks manifest
    chunks_manifest = {
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "total_chunks": len(all_chunks),
        "chunks": all_chunks,
    }

    manifest_path = CHUNKS_DIR.parent / "chunks_manifest.json"
    with open(manifest_path, "w") as f:
        json.dump(chunks_manifest, f, indent=2)

    # Print checkpoint
    print(
        f"CHUNK: Generated {len(all_chunks)} chunks from {len(manifest['files'])} documents"
    )
    print(f"\nChunk counts by type:")
    for chunk_type, count in sorted(type_counts.items()):
        print(f"  {chunk_type}: {count}")

    return len(all_chunks), len(manifest["files"]), type_counts


if __name__ == "__main__":
    main()
