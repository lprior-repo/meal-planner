---
doc_id: concept/windmill/5-step-mocking
chunk_id: concept/windmill/5-step-mocking#chunk-1
heading_path: ["Step mocking / Pin result"]
chunk_type: prose
tokens: 306
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Step mocking / Pin result</title>
  <description>&lt;!-- &lt;doc_metadata&gt; &lt;type&gt;reference&lt;/type&gt; &lt;category&gt;flows&lt;/category&gt; &lt;title&gt;Step Mocking&lt;/title&gt; &lt;description&gt;Mock flow steps for faster development iteration&lt;/description&gt; &lt;created_at&gt;2025-12-28T00:</description>
  <created_at>2026-01-02T19:55:27.991030</created_at>
  <updated_at>2026-01-02T19:55:27.991030</updated_at>
  <language>en</language>
  <sections count="6">
    <section name="Mocking vs Pinning" level="2"/>
    <section name="Accessing step results" level="2"/>
    <section name="Features" level="2"/>
    <section name="History exploration" level="3"/>
    <section name="Pinning results" level="3"/>
    <section name="Mocking" level="3"/>
  </sections>
  <features>
    <feature>accessing_step_results</feature>
    <feature>features</feature>
    <feature>history_exploration</feature>
    <feature>mocking</feature>
    <feature>mocking_vs_pinning</feature>
    <feature>pinning_results</feature>
  </features>
  <dependencies>
    <dependency type="feature">ops/windmill/18-test-flows</dependency>
    <dependency type="feature">tutorial/windmill/4-cache</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../assets/flows/bottom_arrow.png &quot;Bottom arrow&quot;</entity>
    <entity relationship="uses">../assets/flows/test_this_step.png &quot;Test this step&quot;</entity>
    <entity relationship="uses">../assets/flows/pin_result.png &quot;Pin result&quot;</entity>
    <entity relationship="uses">../assets/flows/override_pin.png &quot;Override pin&quot;</entity>
    <entity relationship="uses">../assets/flows/direct_editing.png &quot;Direct editing&quot;</entity>
    <entity relationship="uses">./18_test_flows.mdx</entity>
    <entity relationship="uses">./4_cache.mdx</entity>
  </related_entities>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>windmill,step,concept</tags>
</doc_metadata>
-->

<!--
<doc_metadata>
  <type>reference</type>
  <category>flows</category>
  <title>Step Mocking</title>
  <description>Mock flow steps for faster development iteration</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Step mocking / Pin result" level="1"/>
    <section name="Mocking vs Pinning" level="2"/>
    <section name="Accessing step results" level="2"/>
  </sections>
  <features>
    <feature>step_mocking</feature>
    <feature>pin_result</feature>
    <feature>development_iteration</feature>
    <feature>history_exploration</feature>
  </features>
  <dependencies>
    <dependency type="feature">caching</dependency>
  </dependencies>
  <examples count="2">
    <example>Pin successful run result</example>
    <example>Mock step with custom value</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>windmill,mock,pin,result,development,testing,iteration,cache</tags>
</doc_metadata>
-->

# Step mocking / Pin result

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>flows</category> <title>Step Mocking</title> <description>Mock flow steps for faster development 

Step mocking and pinning results allows faster iteration while building flows. When a step is mocked or pinned, it will immediately return the specified value without performing any computation.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/-cATEh8saqU"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br/>
