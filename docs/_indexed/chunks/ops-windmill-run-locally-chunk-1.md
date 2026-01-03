---
doc_id: ops/windmill/run-locally
chunk_id: ops/windmill/run-locally#chunk-1
heading_path: ["Run locally"]
chunk_type: prose
tokens: 276
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Run locally</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;; import Tabs from &apos;@theme/Tabs&apos;; import TabItem from &apos;@theme/TabItem&apos;;</description>
  <created_at>2026-01-02T19:55:27.527117</created_at>
  <updated_at>2026-01-02T19:55:27.527117</updated_at>
  <language>en</language>
  <sections count="7">
    <section name="Deno / Bun" level="3"/>
    <section name="Python" level="3"/>
    <section name="Interacting with Windmill locally" level="2"/>
    <section name="State" level="3"/>
    <section name="Terminal" level="3"/>
    <section name="VS Code" level="3"/>
    <section name="JetBrains IDEs" level="3"/>
  </sections>
  <features>
    <feature>deno_bun</feature>
    <feature>interacting_with_windmill_locally</feature>
    <feature>jetbrains_ides</feature>
    <feature>js_fullUrl</feature>
    <feature>js_path</feature>
    <feature>js_pathS</feature>
    <feature>python</feature>
    <feature>state</feature>
    <feature>terminal</feature>
    <feature>vs_code</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
    <dependency type="feature">meta/windmill/index-15</dependency>
    <dependency type="feature">meta/windmill/index-14</dependency>
    <dependency type="feature">meta/windmill/index-22</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../../code_editor/index.mdx</entity>
    <entity relationship="uses">./index.mdx</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">../3_cli/index.mdx</entity>
    <entity relationship="uses">../../cli_local_dev/1_vscode-extension/index.mdx</entity>
  </related_entities>
  <examples count="11">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>windmill,run,advanced,operations</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# Run locally

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

Windmill has [its own integrated development environment](../../code_editor/index.mdx). But for iteration, integration with CI/CD and testing purposes you may need to run a script locally that also interacts with Windmill (for example, to retrieve resources).
It will allow you to integrate Windmill with any testing framework.

To setup a local development environment for Windmill, see the dedicated [Local development page](./meta-windmill-index-15.md).

To run scripts locally, you will need to [fill out the context variables](#interacting-with-windmill-locally) that would otherwise be filled out by the Windmill runtime for you.
