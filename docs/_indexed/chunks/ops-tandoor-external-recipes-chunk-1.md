---
doc_id: ops/tandoor/external-recipes
chunk_id: ops/tandoor/external-recipes#chunk-1
heading_path: ["External Recipes"]
chunk_type: prose
tokens: 327
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>External Recipes</title>
  <description>The original intend of this application was to provide a search interface to my large collection of PDF scans of recipes. This feature is now called External recipes.</description>
  <created_at>2026-01-02T19:55:27.265469</created_at>
  <updated_at>2026-01-02T19:55:27.265469</updated_at>
  <language>en</language>
  <sections count="8">
    <section name="Storage" level="2"/>
    <section name="Local" level="3"/>
    <section name="Docker" level="4"/>
    <section name="Dropbox" level="3"/>
    <section name="Nextcloud" level="3"/>
    <section name="Adding External Recipes" level="2"/>
    <section name="Syncing Data" level="2"/>
    <section name="Discovered Recipes" level="2"/>
  </sections>
  <features>
    <feature>adding_external_recipes</feature>
    <feature>discovered_recipes</feature>
    <feature>docker</feature>
    <feature>dropbox</feature>
    <feature>local</feature>
    <feature>nextcloud</feature>
    <feature>storage</feature>
    <feature>syncing_data</feature>
  </features>
  <dependencies>
    <dependency type="service">docker</dependency>
  </dependencies>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>tandoor,advanced,external,operations</tags>
</doc_metadata>
-->

# External Recipes

> **Context**: The original intend of this application was to provide a search interface to my large collection of PDF scans of recipes. This feature is now called E

The original intend of this application was to provide a search interface to my large collection of PDF scans of recipes.
This feature is now called External recipes.

<!-- prettier-ignore -->
!!! info
    Internal recipes are stored in a structured manner inside the database. They can be displayed using the standardized
    interface and support features like shopping lists, scaling and steps.
    External recipes are basically files that are displayed within the interface. The benefit is that you can quickly
    import all your old recipes and convert them one by one.

To use external recipes you will first need to configure a storage source. After that a synced path can be created.
Lastly you will need to sync with the external path and import recipes you desire.
