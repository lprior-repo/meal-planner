---
doc_id: ops/windmill/key-value-stores
chunk_id: ops/windmill/key-value-stores#chunk-1
heading_path: ["NoSQL & Document databases (Mongodb, Key-Value Stores)"]
chunk_type: prose
tokens: 256
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>NoSQL &amp; Document databases (Mongodb, Key-Value Stores)</title>
  <description>This page is part of our section on [Persistent storage &amp; databases](./index.mdx) which covers where to effectively store and manage the data manipulated by Windmill. Check that page for more options </description>
  <created_at>2026-01-02T19:55:27.592686</created_at>
  <updated_at>2026-01-02T19:55:27.592686</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="MongoDB Atlas" level="2"/>
    <section name="Redis" level="2"/>
    <section name="Upstash" level="2"/>
  </sections>
  <features>
    <feature>mongodb_atlas</feature>
    <feature>redis</feature>
    <feature>upstash</feature>
  </features>
  <dependencies>
    <dependency type="service">redis</dependency>
    <dependency type="service">mongodb</dependency>
    <dependency type="feature">meta/windmill/index-25</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">./index.mdx</entity>
    <entity relationship="uses">../../integrations/mongodb.md</entity>
    <entity relationship="uses">../../integrations/redis.md</entity>
    <entity relationship="uses">../../integrations/upstash.md</entity>
  </related_entities>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>windmill,sql,nosql,operations</tags>
</doc_metadata>
-->

# NoSQL & Document databases (Mongodb, Key-Value Stores)

> **Context**: This page is part of our section on [Persistent storage & databases](./meta-windmill-index-25.md) which covers where to effectively store and manage the data manipula

This page is part of our section on [Persistent storage & databases](./meta-windmill-index-25.md) which covers where to effectively store and manage the data manipulated by Windmill. Check that page for more options on data storage.

Key-value stores are a popular choice for managing non-structured data, providing a flexible and scalable solution for various data types and use cases. In the context of Windmill, you can use MongoDB Atlas, Redis, and Upstash to store and manipulate non-structured data effectively.
