# Documentation Quick Reference

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
| `tutorial-*` | 6 | Getting started, step-by-step guides |
| `concept-*` | 22 | Understanding features, architecture |
| `ref-*` | 5 | API references, configuration options |
| `ops-*` | 89 | Installation, deployment, troubleshooting |
| `meta-*` | 0 | Index files, overviews |

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
`{category}-{topic}-chunk-{N}.md`

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
