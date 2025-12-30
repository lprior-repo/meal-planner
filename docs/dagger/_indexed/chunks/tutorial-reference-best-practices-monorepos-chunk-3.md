---
doc_id: tutorial/reference/best-practices-monorepos
chunk_id: tutorial/reference/best-practices-monorepos#chunk-3
heading_path: ["best-practices-monorepos", "Shared Dagger Module"]
chunk_type: prose
tokens: 104
summary: "Create a single, shared automation module which all projects use and contribute to."
---
Create a single, shared automation module which all projects use and contribute to.

This pattern is suitable when there are significant commonalities between projects (e.g., a monorepo with only micro-services or only front-end applications).

### Benefits

- **Code reuse**: Reduces duplication and ensures consistent CI environment
- **Reduced onboarding friction**: No need to create new CI modules when adding projects
- **Best practices**: All projects benefit from shared best practices
- **Knowledge sharing**: Teams learn from each other's CI strategies
