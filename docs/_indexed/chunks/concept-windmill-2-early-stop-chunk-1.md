---
doc_id: concept/windmill/2-early-stop
chunk_id: concept/windmill/2-early-stop#chunk-1
heading_path: ["Early stop / Break"]
chunk_type: prose
tokens: 214
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Early stop / Break</title>
  <description>&lt;!-- &lt;doc_metadata&gt; &lt;type&gt;reference&lt;/type&gt; &lt;category&gt;flows&lt;/category&gt; &lt;title&gt;Early Stop&lt;/title&gt; &lt;description&gt;Stop flow execution early based on conditions&lt;/description&gt; &lt;created_at&gt;2025-12-28T00:00:00</description>
  <created_at>2026-01-02T19:55:27.976310</created_at>
  <updated_at>2026-01-02T19:55:27.976310</updated_at>
  <language>en</language>
  <sections count="2">
    <section name="Early stop for step" level="2"/>
    <section name="Early stop for flow" level="2"/>
  </sections>
  <features>
    <feature>early_stop_for_flow</feature>
    <feature>early_stop_for_step</feature>
  </features>
  <dependencies>
    <dependency type="feature">meta/windmill/index-76</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../core_concepts/5_monitor_past_and_future_runs/index.mdx</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>windmill,concept,early</tags>
</doc_metadata>
-->

<!--
<doc_metadata>
  <type>reference</type>
  <category>flows</category>
  <title>Early Stop</title>
  <description>Stop flow execution early based on conditions</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="2">
    <section name="Early stop / Break" level="1"/>
    <section name="Early stop for step" level="2"/>
    <section name="Early stop for flow" level="2"/>
  </sections>
  <features>
    <feature>early_stop</feature>
    <feature>conditional_termination</feature>
    <feature>predicate_expression</feature>
  </features>
  <dependencies>
    <dependency type="feature">for_loops</dependency>
  </dependencies>
  <examples count="2">
    <example>Stop loop on condition met</example>
    <example>Prevent flow execution based on inputs</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>windmill,early-stop,break,predicate,condition,flow,loop</tags>
</doc_metadata>
-->

# Early stop / Break

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>flows</category> <title>Early Stop</title> <description>Stop flow execution early based on condit

If defined, at the end or before a step, the predicate expression will be evaluated to decide if the flow should stop early.
