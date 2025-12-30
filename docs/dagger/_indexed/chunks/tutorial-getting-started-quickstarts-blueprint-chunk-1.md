---
doc_id: tutorial/getting-started/quickstarts-blueprint
chunk_id: tutorial/getting-started/quickstarts-blueprint#chunk-1
heading_path: ["quickstarts-blueprint"]
chunk_type: prose
tokens: 147
summary: "> **Context**: A Dagger module may reference another module as its blueprint."
---
# Use a Blueprint Module

> **Context**: A Dagger module may reference another module as its blueprint.


A Dagger module may reference another module as its blueprint.

Using a module as a blueprint means that your module will automatically have the functions of the blueprint module directly callable. This is great for platform teams daggerizing many software components with identical stacks because each project does not need to reimplement the same code in every project, they simply install the blueprint.

When you use a blueprint module, the context directory will automatically be your repository rather than the blueprint's repository.

This quickstart will guide you through using a blueprint module in an example application.
