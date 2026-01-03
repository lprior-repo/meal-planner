---
doc_id: ops/moonrepo/codeowners-2
chunk_id: ops/moonrepo/codeowners-2#chunk-1
heading_path: ["Code owners"]
chunk_type: prose
tokens: 313
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Code owners</title>
  <description>Code owners enables companies to define individuals, teams, or groups that are responsible for code in a repository. This is useful in ensuring that pull/merge requests are reviewed and approved by a </description>
  <created_at>2026-01-02T19:55:27.066957</created_at>
  <updated_at>2026-01-02T19:55:27.066957</updated_at>
  <language>en</language>
  <sections count="11">
    <section name="Defining owners" level="2"/>
    <section name="Project-level" level="3"/>
    <section name="GitHub" level="4"/>
    <section name="GitLab" level="4"/>
    <section name="Bitbucket" level="4"/>
    <section name="Workspace-level" level="3"/>
    <section name="Generating `CODEOWNERS`" level="2"/>
    <section name="FAQ" level="2"/>
    <section name="What providers or formats are supported?" level="3"/>
    <section name="Where does the `CODEOWNERS` file get created?" level="3"/>
  </sections>
  <features>
    <feature>bitbucket</feature>
    <feature>defining_owners</feature>
    <feature>generating_codeowners</feature>
    <feature>github</feature>
    <feature>gitlab</feature>
    <feature>project-level</feature>
    <feature>what_providers_or_formats_are_supported</feature>
    <feature>workspace-level</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/commands/sync/codeowners</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
  </related_entities>
  <examples count="8">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>code,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# Code owners

> **Context**: Code owners enables companies to define individuals, teams, or groups that are responsible for code in a repository. This is useful in ensuring that p

v1.8.0

Code owners enables companies to define individuals, teams, or groups that are responsible for code in a repository. This is useful in ensuring that pull/merge requests are reviewed and approved by a specific set of contributors, before the branch is merged into the base branch.

With that being said, moon *does not* implement a custom code owners solution, and instead builds upon the popular `CODEOWNERS` integration in VCS providers, like GitHub, GitLab, and Bitbucket.
