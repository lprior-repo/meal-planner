---
id: ops/windmill/key-value-stores
title: "NoSQL & Document databases (Mongodb, Key-Value Stores)"
category: ops
tags: ["windmill", "sql", "nosql", "operations"]
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

## MongoDB Atlas

[MongoDB Atlas](https://www.mongodb.com/atlas/database) is a managed database-as-a-service platform that provides an efficient way to deploy, manage, and optimize MongoDB instances. As a document-oriented NoSQL database, MongoDB is well-suited for handling large volumes of unstructured data. Its dynamic schema enables the storage and retrieval of JSON-like documents with diverse structures, making it a suitable option for managing non-structured data.

To use MongoDB Atlas with Windmill:

1. [Sign-up to Atlas](https://www.mongodb.com/cloud/atlas/signup).

2. [Create a database](https://www.mongodb.com/basics/create-database).

3. [Integrate it to Windmill](../../integrations/mongodb.md) by filling the [resource type details](https://hub.windmill.dev/resource_types/22/).

:::tip

You can find examples and premade MonggoDB scripts on [Windmill Hub](https://hub.windmill.dev/integrations/mongodb).

:::

## Redis

[Redis](https://redis.io/) is an open-source, in-memory key-value store that can be used for caching, message brokering, and real-time analytics. It supports a variety of data structures such as strings, lists, sets, and hashes, providing flexibility for non-structured data storage and management. Redis is known for its high performance and low-latency data access, making it a suitable choice for applications requiring fast data retrieval and processing.

To use Redis with Windmill:

1. [Sign-up to Redis](https://redis.com/try-free/).

2. [Create a database](https://developer.redis.com/create).

3. [Integrate it to Windmill](../../integrations/redis.md) by filling the [resource type details](https://hub.windmill.dev/resource_types/22/) following the same schema as MongoDB Atlas.

## Upstash

[Upstash](https://upstash.com/) is a serverless, edge-optimized key-value store designed for low-latency access to non-structured data. It is built on top of Redis, offering similar performance benefits and data structure support while adding serverless capabilities, making it easy to scale your data storage needs.

To use Upstash with Windmill:

1. [Sign-up to Upstash](https://console.upstash.com/).

2. [Create a database](https://docs.upstash.com/redis).

3. [Integrate it to Windmill](../../integrations/upstash.md) by filling the [resource type details](https://hub.windmill.dev/resource_types/22/) following the same schema as MongoDB Atlas.


## See Also

- [Persistent storage & databases](./index.mdx)
- [Integrate it to Windmill](../../integrations/mongodb.md)
- [Integrate it to Windmill](../../integrations/redis.md)
- [Integrate it to Windmill](../../integrations/upstash.md)
