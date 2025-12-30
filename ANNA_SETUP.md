# CodeAnna Setup Guide

## Installation

CodeAnna is an AI-assisted coding tool. This document describes how to set it up for the meal-planner repository.

### Prerequisites

CodeAnna requires:
- Git repository
- Python 3.8+
- File system access

### Installation

```bash
# Clone CodeAnna (if not already installed)
git clone https://github.com/superclaude-org/CodeAnna.git
cd CodeAnna

# Install CodeAnna
pip install -e .

# Verify installation
anna --version
```

### Configuration

CodeAnna automatically indexes Git repositories. No manual configuration needed.

### Usage

```bash
# Get help
anna help

# Generate code with context
anna "Create a Rust script that uses wmill SDK to access resources"

# Refactor code
anna "Refactor this function to be more efficient and add proper error handling"

# Explain code
anna "Explain what this code does and how it fits into the overall architecture"
```

### Integration with meal-planner

CodeAnna is now configured to work with:

- **Indexed Repository**: All source code, documentation, and configuration files
- **Context Awareness**: Full understanding of codebase architecture and patterns
- **Documentation Indexing**: Uses XML metadata and DAG structure for docs
- **Enhanced RAG**: Can retrieve context from INDEXED_KNOWLEDGE.json

### Context Sources

CodeAnna will index and provide context from:

1. **Source Code** (`src/` directory)
   - FatSecret implementation (`src/fatsecret/`)
   - Main application code (`main.rs`)

2. **Documentation** (`docs/` directory)
   - Windmill documentation with XML metadata
   - Compass artifact with XML metadata
   - AGENTS.md with indexing guidelines

3. **Configuration Files**
   - Cargo.toml
   - Makefile
   - mise.toml
   - openapi.yaml
   - Taskfile.yml

4. **Database Schema** (`schema/` directory)
   - All SQL migration files

5. **Index Files**
   - docs/windmill/DOCUMENTATION_INDEX.xml
   - docs/windmill/INDEXED_KNOWLEDGE.json
   - docs/windmill/INDEXING_SYSTEM.md

### Best Practices for CodeAnna

1. **Use Contextual Queries**: When asking for code changes, reference specific files
2. **Leverage DAG Knowledge**: Use document relationships from INDEXED_KNOWLEDGE.json
3. **Follow Code Style**: Maintain consistency with existing codebase patterns
4. **Document Changes**: Update relevant docs when making changes
5. **Use XML Metadata**: Reference docs by entity names and tags from index

### Example Commands

```bash
# Get help with CodeAnna context
anna --help

# Generate Rust code with wmill SDK knowledge
anna "Write a Windmill Rust script that gets a PostgreSQL resource and runs a query. The script should use the wmill crate version ^1.0 and handle errors properly with anyhow."

# Refactor with specific context
anna src/fatsecret/core/oauth_auth.rs "Refactor the OAuth implementation to follow the patterns in other files, make sure to use proper error handling with anyhow::Result"

# Generate tests
anna "Create unit tests for the fatsecret/oauth module following the patterns in the codebase. Use tokio::test and mock the wmill SDK."

# Explain architecture
anna "Explain how the meal-planner application is structured, focusing on the FatSecret integration, database schema, and Windmill scripts organization."
```

### Troubleshooting

**CodeAnna not indexing repository?**
```bash
# Reindex repository
cd /home/lewis/src/meal-planner
anna reindex
```

**CodeAnna not providing context?**
```bash
# Check if repository is indexed
anna status

# Force reindex
anna index --force
```

**CodeAnna commands not working?**
```bash
# Check version
anna --version

# Verify Git access
git status
```

### Integration with Documentation Indexing

When CodeAnna generates code, it can now leverage the XML metadata and DAG structure:

1. **Entity References**: Query by entity names (e.g., "retries", "wmill_cli")
2. **DAG Traversal**: Follow relationships to understand dependencies
3. **Category Filtering**: Find docs by category (flows, core_concepts, cli, sdk, deployment)
4. **Tag Search**: Search by tags for relevant documentation
5. **Difficulty-Based Learning**: Progress from beginner to advanced topics

### Query Examples

```bash
# Find documentation about retries
anna "Show me the documentation about Windmill retries feature, including examples and how it integrates with error handlers"

# Get deployment information
anna "I need to deploy the meal-planner to production. What are the deployment steps mentioned in the documentation? Use the DEPLOYMENT_GUIDE.md and staging_prod docs."

# Understand codebase architecture
anna "Explain the overall architecture of the meal-planner application, focusing on how the FatSecret module integrates with the database and how Windmill scripts are used."

# Generate code with proper error handling
anna "Write a Rust function that uses wmill::Windmill to access resources. Follow the patterns in the compass_artifact document for proper error handling with anyhow::Result. Include the Cargo.toml dependency format."
```

## Advanced Features

### Memory Management

CodeAnna can learn from the codebase:

```bash
# Learn patterns
anna learn "The fatsecret module uses a specific pattern for OAuth. Remember this for future work."
```

### Context Injection

Always provide relevant context when asking CodeAnna:

```bash
# With context
anna "Using the documentation in docs/windmill/DEPLOYMENT_GUIDE.md, create a script that deploys resources to staging."

# From specific file
anna "Based on src/fatsecret/core/oauth_auth.rs, suggest improvements to the error handling."
```

## Verification

After setup, verify CodeAnna is working:

```bash
# Check CodeAnna status
anna status

# Test basic query
anna "What is the purpose of the meal-planner project?"

# Verify indexing
ls ~/.cache/CodeAnna/
```

## Maintenance

### Updating Index

When adding new files or refactoring:

```bash
# Reindex to update CodeAnna's knowledge
cd /home/lewis/src/meal-planner
anna reindex
```

### Cleaning Cache

```bash
# Clear CodeAnna cache
rm -rf ~/.cache/CodeAnna/
```

---

**Created**: 2025-12-29
**CodeAnna Version**: Latest from GitHub
**Repo Path**: /home/lewis/src/meal-planner
**Documentation**: docs/windmill/INDEXING_SYSTEM.md, docs/windmill/DOCUMENTATION_INDEX.xml, docs/windmill/INDEXED_KNOWLEDGE.json