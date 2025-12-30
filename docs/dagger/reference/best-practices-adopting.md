# Adopting Dagger

A guide for adopting Dagger in your project, team, or organization.

## Phase 1: Research

### Join the Discord

Before anything, join the [Discord server](https://discord.gg/dagger-io). It's the best place to ask questions, get inspiration, and ask for help.

### Look for inspiration

Learn about other projects who have successfully adopted Dagger through [case studies](https://dagger.io/resources/Case-Studies) and [demo videos](https://dagger.io/resources/Videos).

### Look for red flags

Your project may not be a good fit for Dagger if:
- It is so early that it doesn't need CI
- Your *only* output is a Windows, Mac, iOS or Android application
- You are happily using a monolithic toolchain (Gradle, Nix, Bazel)
- Your workflows are heavily dependent on Windows or Mac runners

## Phase 2: The POC

### Scoping your POC

The ideal first workflow has three properties:

1. It suffers from a **hair-on-fire problem** which daggerizing can solve
2. It can be daggerized within a week
3. You have the authority to daggerize it

### Choosing a language

- **Optimize for participation** - The more people on the team can participate, the better
- **Check SDK availability** - Go, Python, TypeScript are official; others are community-supported
- **Polyglot workflows for a polyglot stack** - Write different modules for each team's preferred language

### Integrating with CI

1. Decide which event should trigger which Dagger workflow
2. Map inputs from the environment into arguments to the Dagger functions
3. Write the resulting `dagger call` command for each workflow

**Key notes:**
- Don't hesitate to run both daggerized and non-daggerized workflows in parallel
- Dagger workflows are not distributed - each `dagger call` executes on a single Dagger engine
- Caching makes everything faster but is harder in CI with ephemeral runners

## Phase 3: Expand

### Incremental expansion

Once your POC is successful, repeat the process with another piece, then another one.

### All-in expansion

This strategy usually coincides with a major CI migration. Contact [solutions@dagger.io](mailto:solutions@dagger.io) to discuss.

## Phase 4: Spin Out Reusable Modules

As you develop workflows:
1. Initially mix all functions together in the same module for speed
2. Spin out reusable functions into sub-modules
3. Centralize shared modules into a dedicated repository
4. Consider open-sourcing modules by publishing on the Daggerverse
