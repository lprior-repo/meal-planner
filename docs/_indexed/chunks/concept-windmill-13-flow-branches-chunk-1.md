---
doc_id: concept/windmill/13-flow-branches
chunk_id: concept/windmill/13-flow-branches#chunk-1
heading_path: ["Branches"]
chunk_type: prose
tokens: 256
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Branches</title>
  <description>&lt;!-- &lt;doc_metadata&gt; &lt;type&gt;reference&lt;/type&gt; &lt;category&gt;flows&lt;/category&gt; &lt;title&gt;Flow Branches&lt;/title&gt; &lt;description&gt;Split flow execution based on conditions&lt;/description&gt; &lt;created_at&gt;2025-12-28T00:00:00Z&lt;</description>
  <created_at>2026-01-02T19:55:27.947064</created_at>
  <updated_at>2026-01-02T19:55:27.947064</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Branch one" level="2"/>
    <section name="Branch all" level="2"/>
    <section name="Predicate expression" level="2"/>
  </sections>
  <features>
    <feature>branch_all</feature>
    <feature>branch_one</feature>
    <feature>predicate_expression</feature>
  </features>
  <dependencies>
    <dependency type="feature">meta/windmill/index-37</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../assets/flows/flow_branch_one.png.webp</entity>
    <entity relationship="uses">/blog/handler-slack-commands</entity>
    <entity relationship="uses">../core_concepts/22_ai_generation/index.mdx</entity>
  </related_entities>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>windmill,concept,branches</tags>
</doc_metadata>
-->

<!--
<doc_metadata>
  <type>reference</type>
  <category>flows</category>
  <title>Flow Branches</title>
  <description>Split flow execution based on conditions</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Branches" level="1"/>
    <section name="Branch one" level="2"/>
    <section name="Branch all" level="2"/>
    <section name="Predicate expression" level="2"/>
  </sections>
  <features>
    <feature>flow_branches</feature>
    <feature>conditional_execution</feature>
    <feature>parallel_branches</feature>
    <feature>branch_one</feature>
    <feature>branch_all</feature>
  </features>
  <dependencies>
    <dependency type="feature">for_loops</dependency>
    <dependency type="feature">error_handler</dependency>
  </dependencies>
  <examples count="2">
    <example>Handle Slackbot commands</example>
    <example>CRM automation with branches</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>5</estimated_reading_time>
  <tags>windmill,branch,condition,predicate,parallel</tags>
</doc_metadata>
-->

# Branches

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>flows</category> <title>Flow Branches</title> <description>Split flow execution based on conditio

Branches allow to split the execution of the flow based on a condition.

<video
    className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
    autoPlay
    loop
    controls
    id="main-video"
    src="/videos/flow-branch.mp4"
/>

<br/>

There are two types of branches:

- **Branch one**: the branch will be executed if its condition is true, otherwise the default branch will be executed.
- **Branch all**: all the branches will be executed.
