---
id: ops/tandoor/pycharm
title: "Pycharm"
category: ops
tags: ["tandoor", "pycharm", "operations"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>Pycharm</title>
  <description>PyCharm can be configured to format and lint on save. Doing so requires some manual configuration as outlined below.</description>
  <created_at>2026-01-02T19:55:27.245940</created_at>
  <updated_at>2026-01-02T19:55:27.245940</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Setup File Watchers" level="2"/>
    <section name="Setup flake8 Watcher" level="2"/>
    <section name="Setup isort" level="2"/>
    <section name="Setup yapf" level="2"/>
    <section name="Setup prettier" level="2"/>
  </sections>
  <features>
    <feature>setup_file_watchers</feature>
    <feature>setup_flake8_watcher</feature>
    <feature>setup_isort</feature>
    <feature>setup_prettier</feature>
    <feature>setup_yapf</feature>
  </features>
  <related_entities>
    <entity relationship="uses">assets/flake8_watcher.png</entity>
    <entity relationship="uses">assets/linting_error.png</entity>
    <entity relationship="uses">assets/isort_watcher.png</entity>
    <entity relationship="uses">assets/yapf_watcher.png</entity>
    <entity relationship="uses">assets/prettier_watcher.png</entity>
  </related_entities>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>tandoor,pycharm,operations</tags>
</doc_metadata>
-->

# Pycharm

> **Context**: PyCharm can be configured to format and lint on save. Doing so requires some manual configuration as outlined below.

PyCharm can be configured to format and lint on save. Doing so requires some manual configuration as outlined below.

## Setup File Watchers

1. Navigate to File -> Settings -> Plugins
2. Download and install [File Watchers](https://plugins.jetbrains.com/plugin/7177-file-watchers)
3. Navigate to File -> Settings -> Tools -> Black
4. Confirm 'Use Black Formatter' is unchecked for both 'On code reformat' and 'On save'

## Setup flake8 Watcher

1. Navigate to File -> Settings -> Tools -> File Watchers
2. Click the '+' to add a new watcher.
3. Configure the watcher as below.

   ![flake8_watcher](assets/flake8_watcher.png)

4. Navigate to File -> Settings -> Editor -> Inspections -> File watcher problems
5. Under Severity select 'Edit Severities'
6. Click the '+' to add a severity calling it 'Linting Error'
7. Configure a background and effect as below.

   ![linting error](assets/linting_error.png)

## Setup isort

1. Navigate to File -> Settings -> Tools -> File Watchers
2. Click the '+' to add a new watcher.
3. Configure the watcher as below.

   ![yapf_watcher](assets/isort_watcher.png)

## Setup yapf

1. Navigate to File -> Settings -> Tools -> File Watchers
2. Click the '+' to add a new watcher.
3. Configure the watcher as below.

   ![yapf_watcher](assets/yapf_watcher.png)

<!-- prettier-ignore -->
!!! hint
    Adding a comma at the end of a list will trigger yapf to put each element of the list on a new line

<!-- prettier-ignore -->
!!! note
     In order to debug vue yarn and vite servers must be started before starting the django server.

## Setup prettier

1. Navigate to File -> Settings -> Tools -> File Watchers
2. Click the '+' to add a new watcher.
3. Change 'File Type' to 'Any'.
4. Click the three dots next to 'Scope' to create a custom scope.
5. Click '+' to add a new scope

- Name: prettier
- Pattern: `file:vue/src//*||file:vue3/src//*||file:docs//*`

6. Configure the watcher as below.

   ![perttier_watcher](assets/prettier_watcher.png)

- Arguments: `--cwd $ProjectFileDir$\vue prettier -w --config $ProjectFileDir$\.prettierrc $FilePath$`


## See Also

- [flake8_watcher](assets/flake8_watcher.png)
- [linting error](assets/linting_error.png)
- [yapf_watcher](assets/isort_watcher.png)
- [yapf_watcher](assets/yapf_watcher.png)
- [perttier_watcher](assets/prettier_watcher.png)
