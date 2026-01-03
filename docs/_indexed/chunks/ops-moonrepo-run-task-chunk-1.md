---
doc_id: ops/moonrepo/run-task
chunk_id: ops/moonrepo/run-task#chunk-1
heading_path: ["Run a task"]
chunk_type: prose
tokens: 276
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Run a task</title>
  <description>Even though we&apos;ve created a task, it&apos;s not useful unless we *run it*, which is done with the `moon run &lt;target&gt;` command. This command requires a single argument, a primary target, which is the pairin</description>
  <created_at>2026-01-02T19:55:27.230207</created_at>
  <updated_at>2026-01-02T19:55:27.230207</updated_at>
  <language>en</language>
  <sections count="7">
    <section name="Running dependents" level="2"/>
    <section name="Running based on affected files only" level="2"/>
    <section name="Using remote changes" level="3"/>
    <section name="Filtering based on change status" level="3"/>
    <section name="Passing arguments to the underlying command" level="2"/>
    <section name="Advanced run targeting" level="2"/>
    <section name="Next steps" level="2"/>
  </sections>
  <features>
    <feature>advanced_run_targeting</feature>
    <feature>filtering_based_on_change_status</feature>
    <feature>next_steps</feature>
    <feature>running_based_on_affected_files_only</feature>
    <feature>running_dependents</feature>
    <feature>using_remote_changes</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/migrate-to-moon</entity>
    <entity relationship="uses">/docs/concepts/task</entity>
    <entity relationship="uses">/docs/commands/run</entity>
  </related_entities>
  <examples count="9">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>run,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# Run a task

> **Context**: Even though we've created a task, it's not useful unless we *run it*, which is done with the `moon run <target>` command. This command requires a sing

Even though we've created a task, it's not useful unless we *run it*, which is done with the `moon run <target>` command. This command requires a single argument, a primary target, which is the pairing of a scope and task name. In the example below, our project is `app`, the task is `build`, and the target is `app:build`.

```
$ moon run app:build
