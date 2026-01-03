---
doc_id: ops/tandoor/import-export
chunk_id: ops/tandoor/import-export#chunk-1
heading_path: ["Import Export"]
chunk_type: prose
tokens: 585
summary: "Import Export"
---

# Import Export

> **Context**: This application features a very versatile import and export feature in order to offer the best experience possible and allow you to freely choose whe

This application features a very versatile import and export feature in order
to offer the best experience possible and allow you to freely choose where your data goes.

!!! WARNING "WIP"
    The Module is relatively new. There is a known issue with [Timeouts](https://github.com/vabene1111/recipes/issues/417) on large exports.
    A fix is being developed and will likely be released with the next version.

The Module is built with maximum flexibility and expandability in mind and allows to easily add new
integrations to allow you to both import and export your recipes into whatever format you desire.

Feel like there is an important integration missing? Just take a look at the [integration issues](https://github.com/vabene1111/recipes/issues?q=is%3Aissue+is%3Aopen+label%3Aintegration) or open a new one
if your favorite one is missing.

!!! info "Export"
    I strongly believe in everyone's right to use their data as they please and therefore want to give you
    the best possible flexibility with your recipes.
    That said for most of the people getting this application running with their recipes is the biggest priority.
    Because of this importing as many formats as possible is prioritized over exporting.
    Exporter for the different formats will follow over time.

Overview of the capabilities of the different integrations.

| Integration        | Import | Export | Images |
| ------------------ | ------ | ------ | ------ |
| Default            | ✔️     | ✔️     | ✔️     |
| Nextcloud          | ✔️     | ⌚     | ✔️     |
| Mealie             | ✔️     | ⌚     | ✔️     |
| Chowdown           | ✔️     | ⌚     | ✔️     |
| Safron             | ✔️     | ✔️     | ❌     |
| Paprika            | ✔️     | ⌚     | ✔️     |
| ChefTap            | ✔️     | ❌     | ❌     |
| Pepperplate        | ✔️     | ⌚     | ❌     |
| RecipeSage         | ✔️     | ✔️     | ✔️     |
| Rezeptsuite.de     | ✔️     | ❌     | ✔️     |
| Domestica          | ✔️     | ⌚     | ✔️     |
| MealMaster         | ✔️     | ❌     | ❌     |
| RezKonv            | ✔️     | ❌     | ❌     |
| OpenEats           | ✔️     | ❌     | ⌚     |
| Plantoeat          | ✔️     | ❌     | ✔      |
| CookBookApp        | ✔️     | ⌚     | ✔️     |
| CopyMeThat         | ✔️     | ❌     | ✔️     |
| Melarecipes        | ✔️     | ⌚     | ✔️     |
| Cookmate           | ✔️     | ⌚     | ✔️     |
| PDF (experimental) | ⌚️    | ✔️     | ✔️     |
| Gourmet            | ✔️     | ❌     | ✔️     |

✔️ = implemented, ❌ = not implemented and not possible/planned, ⌚ = not yet implemented
