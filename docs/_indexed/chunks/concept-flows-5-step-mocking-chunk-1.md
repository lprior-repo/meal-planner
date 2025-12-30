---
doc_id: concept/flows/5-step-mocking
chunk_id: concept/flows/5-step-mocking#chunk-1
heading_path: ["Step mocking / Pin result"]
chunk_type: prose
tokens: 178
summary: "<!--"
---

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
