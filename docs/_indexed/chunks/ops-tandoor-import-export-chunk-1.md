---
doc_id: ops/tandoor/import-export
chunk_id: ops/tandoor/import-export#chunk-1
heading_path: ["Import Export"]
chunk_type: prose
tokens: 718
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>Import Export</title>
  <description>This application features a very versatile import and export feature in order to offer the best experience possible and allow you to freely choose where your data goes.</description>
  <created_at>2026-01-02T19:55:27.268853</created_at>
  <updated_at>2026-01-02T19:55:27.268853</updated_at>
  <language>en</language>
  <sections count="23">
    <section name="Default" level="2"/>
    <section name="RecipeSage" level="2"/>
    <section name="Domestica" level="2"/>
    <section name="Nextcloud" level="2"/>
    <section name="Mealie" level="2"/>
    <section name="Chowdown" level="2"/>
    <section name="Safron" level="2"/>
    <section name="Paprika" level="2"/>
    <section name="Pepperplate" level="2"/>
    <section name="ChefTap" level="2"/>
  </sections>
  <features>
    <feature>cheftap</feature>
    <feature>chowdown</feature>
    <feature>cookbookapp</feature>
    <feature>cookmate</feature>
    <feature>copymethat</feature>
    <feature>default</feature>
    <feature>domestica</feature>
    <feature>gourmet</feature>
    <feature>mealie</feature>
    <feature>mealmaster</feature>
    <feature>melarecipes</feature>
    <feature>nextcloud</feature>
    <feature>openeats</feature>
    <feature>paprika</feature>
    <feature>pepperplate</feature>
  </features>
  <dependencies>
    <dependency type="service">docker</dependency>
  </dependencies>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>10</estimated_reading_time>
  <tags>import,tandoor,advanced,operations</tags>
</doc_metadata>
-->

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
