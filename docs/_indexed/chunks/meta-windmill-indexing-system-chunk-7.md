---
doc_id: meta/windmill/indexing-system
chunk_id: meta/windmill/indexing-system#chunk-7
heading_path: ["Windmill Documentation Indexing System", "XML Metadata Schema"]
chunk_type: prose
tokens: 57
summary: "XML Metadata Schema"
---

## XML Metadata Schema

Each document includes:

```xml
<doc_metadata>
  <type>reference|guide|tutorial</type>
  <category>flows|core_concepts|cli|sdk|deployment</category>
  <title>Document Title</title>
  <description>Brief description</description>
  <created_at>ISO-8601 timestamp</created_at>
  <updated_at>ISO-8601 timestamp</updated_at>
  <language>en|es|fr</language>
  <sections count="N">
    <section name="Section Name" level="1|2|3"/>
  </sections>
  <features>
    <feature>feature_name</feature>
  </features>
  <dependencies>
    <dependency type="feature|tool|service|crate">dependency_id</dependency>
  </dependencies>
  <examples count="N">
    <example>Example description</example>
  </examples>
  <difficulty_level>beginner|intermediate|advanced</difficulty_level>
  <estimated_reading_time>minutes</estimated_reading_time>
  <tags>tag1,tag2,tag3</tags>
</doc_metadata>
```
