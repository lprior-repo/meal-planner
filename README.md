# Meal Planner: A Grand Experiment in Vibe Engineering

## What This Project Actually Is

**Vibe Engineering**: Moving a level up the software stack where AI writes all the code, and I provide architectural oversight, design guidance, code review, testing, and quality gates. Rather than me writing code and using AI as a tool, I'm setting the vision and ensuring quality while the AI handles implementation.

**The Challenge**: Can we achieve production-grade software by having AI write everything, but with rigorous human oversight on design, semantics, tests, and architecture?

## Why Rust? (And Why I Don't Know Rust)

I don't actually know Rust. What I do know is production-grade software design, system architecture, testing strategies, and quality gates.

**Rust was chosen precisely because I don't know it:**

- **Safety by default**: The compiler catches entire classes of errors automatically (memory safety, thread safety, null pointers). AI can't introduce segfaults or data races - the language rejects them.
- **Fast feedback loop**: AI gets instant feedback from the Rust compiler. Write bad code → compiler rejects it → AI learns and fixes it immediately. No mysterious runtime failures.
- **Eliminate whole categories of AI errors**: Linting (clippy) catches logic errors, formatting (rustfmt) enforces style, type system enforces contracts. These aren't nice-to-haves; they're mandatory.
- **Stack on quality gates**: Build pipeline validates format, lints, tests, then compiles. AI can't ship code that doesn't pass every gate.

Plus, I get to say it's written in Rust. Which is objectively cooler than saying "I used Python" or "written in Go" - and it actually follows from the design philosophy.

## The Vibe Engineering Process

1. **I define semantics**: Architecture, API design, data models, error handling strategy
2. **AI implements**: Writes all code, tests, documentation
3. **I review**: Architecture, design patterns, test coverage, code clarity
4. **Compiler enforces**: Type safety, memory safety, code style
5. **Tests validate**: Functional correctness, edge cases, integration
6. **Pipeline gates**: Nothing ships without passing fmt, clippy, tests, build

**Result**: Code written by AI, but shaped by human judgment at every architectural decision point.

## What Does It Do?

Meal planning application that:

- **Integrates FatSecret**: OAuth-authenticated nutrition tracking (API integration, encryption, secure storage)
- **Integrates Tandoor**: Recipe management and food database
- **Manages workflows**: Automated recipe import, nutrition enrichment, meal planning
- **Handles real OAuth**: 3-legged OAuth flow with secure token storage in encrypted Windmill database
- **Production quality**: Domain-driven design, bounded contexts, comprehensive tests, type-safe APIs

## Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| **Language** | Rust | Safety, compiler feedback, type system |
| **Orchestration** | Windmill | Enforce clean architecture: binaries do ONE thing, flows compose them |
| **Build** | Moon | Cached, parallel task execution |
| **Database** | PostgreSQL | ACID, structured data, Windmill integration |
| **Testing** | cargo test, nextest | Parallel, comprehensive coverage |
| **Linting** | Clippy | Catches logic and style errors |
| **Secrets** | Windmill + pass | Encrypted at rest, GPG locally |

## Windmill: Architecture as Tooling

Windmill isn't just orchestration - it's a **constraint that forces good design**:

- **Small binaries**: Each does ONE thing (JSON in → JSON out, ~50 lines max)
- **Flows compose**: Complex workflows are Windmill flows calling binaries
- **No cross-domain logic in code**: Recipe domain doesn't know about nutrition domain
- **Explicit data flow**: Flows show exactly how data moves (no hidden dependencies)
- **Built-in reliability**: Retries, error handling, scheduling in Windmill, not Rust

This architecture pattern keeps code clean: binaries are pure functions, orchestration is explicit, and testing is straightforward.

**Also**: I wanted to toy with Windmill as a tool. It's powerful and underutilized - most projects don't leverage it for architectural patterns, just task scheduling.

## Project Quality Gates

Every commit must pass:

1. **Format check** (`cargo fmt`)
2. **Linting** (`cargo clippy` with `-D warnings`)
3. **Tests** (integration + unit tests)
4. **Build** (release binary compilation)
5. **Documentation** (Markdown validation)

Code that doesn't pass all gates **doesn't ship**.

## Key Accomplishments

- ✅ **110 binary tests**: Comprehensive coverage of all operations
- ✅ **FatSecret OAuth**: Full 3-legged flow with secure storage
- ✅ **Tandoor integration**: Recipe retrieval, creation, keyword management
- ✅ **Type-safe design**: No runtime type errors possible
- ✅ **Domain-driven**: Clean separation between recipe and nutrition domains
- ✅ **Production patterns**: Proper error handling, logging, encryption

## Documentation

All docs designed for both AI agents and humans:

- [docs/README.md](docs/README.md) - Documentation navigation
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - How the code is organized
- [docs/MOON_CI_PIPELINE.md](docs/MOON_CI_PIPELINE.md) - Build and test
- [docs/FATSECRET_OAUTH_SETUP.md](docs/FATSECRET_OAUTH_SETUP.md) - Initial OAuth setup
- [docs/RECIPE_IMPORT_PIPELINE.md](docs/RECIPE_IMPORT_PIPELINE.md) - Recipe import feature
- [AGENTS.md](AGENTS.md) - For AI agents working on the codebase

## Getting Started

```bash
# View architecture and design
cat docs/ARCHITECTURE.md

# Build and test
moon run :ci

# Deploy to Windmill
moon run :deploy
```

## The Experiment

This project tests whether high-quality production software can be built with:

- ✅ AI writing 100% of code
- ✅ Human design and architecture
- ✅ Strong quality gates (linting, testing, compilation)
- ✅ Type safety as guardrails
- ✅ Domain-driven design principles
- ✅ Comprehensive documentation

**So far**: It's working. The combination of Rust's safety, comprehensive testing, and human oversight on design creates genuinely high-quality software - without me needing to write a single line of code.

## Why This Matters

Most discussions about AI coding assume either "AI writes everything" (unreliable) or "AI as code assistant" (incremental). This explores a third path: **AI writes implementation, humans own architecture and design**.

It suggests that the future of software might not be about AI replacing engineers, but about different roles:
- **Humans**: Design, architecture, vision, quality standards
- **AI**: Implementation, tests, iteration, documentation
- **Tools**: Enforce standards (compilers, linters, tests)

---

## I'd Just Like to Interject for a Moment

![Arch Linux Meme](https://analyticsindiamag.com/wp-content/uploads/2023/01/ae2.jpg)

Yes, it's written in Rust. No, I don't use Arch Linux (yet).

---

**Status**: Active experiment. Contributions welcome. Let's see how far we can push "Vibe Engineering."

**Made with**: Rust, discipline, and the firm belief that AI can write good code if we set high enough standards.

**Says in Arch btw**: It's written in Rust 🦀
