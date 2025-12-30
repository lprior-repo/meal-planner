# Monorepos

Best practices for using Dagger with monorepos.

## Top-level Dagger Module

Create a top-level Dagger module for the monorepo, attach sub-modules for each component, and model the Dagger module dependencies on the logical dependencies between components.

This pattern is suitable when there are dependencies but differences between the projects (e.g., SDKs, CLIs, web applications, docs with different requirements).

### Benefits

- **Easier debugging**: Sub-modules provide a way to separate and debug business logic for different workflows
- **Code reuse**: Sub-modules in different projects can import each other
- **Improved performance**: The top-level module can orchestrate sub-modules using native concurrency features

## Shared Dagger Module

Create a single, shared automation module which all projects use and contribute to.

This pattern is suitable when there are significant commonalities between projects (e.g., a monorepo with only micro-services or only front-end applications).

### Benefits

- **Code reuse**: Reduces duplication and ensures consistent CI environment
- **Reduced onboarding friction**: No need to create new CI modules when adding projects
- **Best practices**: All projects benefit from shared best practices
- **Knowledge sharing**: Teams learn from each other's CI strategies

## Optimization Considerations

When optimizing monorepo builds, there are two layers to keep in mind:

1. **Dagger's layer cache**: Even if unnecessary CI jobs are triggered, Dagger's layer cache allows most to finish almost instantly. This minimizes infrastructure overhead and makes CI configurations smaller and less fragile.

2. **CI-specific event filters**: These can serve as a secondary optimization but are not as portable as Dagger modules. Use only when absolutely necessary.
