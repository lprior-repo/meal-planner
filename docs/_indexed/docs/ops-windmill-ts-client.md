---
id: ops/windmill/ts-client
title: "TypeScript client"
category: ops
tags: ["windmill", "typescript", "operations"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>TypeScript client</title>
  <description>import Tabs from &apos;@theme/Tabs&apos;; import TabItem from &apos;@theme/TabItem&apos;; import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:27.471765</created_at>
  <updated_at>2026-01-02T19:55:27.471765</updated_at>
  <language>en</language>
  <sections count="2">
    <section name="Installation" level="2"/>
    <section name="Usage" level="2"/>
  </sections>
  <features>
    <feature>installation</feature>
    <feature>js_main</feature>
    <feature>js_x</feature>
    <feature>usage</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
  </dependencies>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>windmill,typescript,operations</tags>
</doc_metadata>
-->

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';
import DocCard from '@site/src/components/DocCard';

# TypeScript client

> **Context**: import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem'; import DocCard from '@site/src/components/DocCard';

The TypeScript client for Windmill allows you to interact with the Windmill platform using TypeScript in [Bun](https://bun.sh/) / [Deno](https://deno.land/) runtime. This client provides a set of functions and utilities to access Windmill resources and perform various operations.

The TypeScript Windmill SDK can be found at https://app.windmill.dev/tsdocs/modules.html

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="TypeScript Windmill SDK"
		description="TypeScript SDK for Windmill"
		href="https://app.windmill.dev/tsdocs/modules.html"
	/>
</div>

## Installation

To use the TypeScript client, you need to have Deno or Bun installed on your system. Follow the installation instructions from the official [Deno documentation](https://deno.land/manual@v1.36.1/getting_started/installation) or [Bun documentation](https://bun.sh/docs/installation).

Once Deno/Bun is installed, you can import the `windmill` module directly from the Deno third-party module registry.

<Tabs className="unique-tabs">
<TabItem value="deno" label="TypeScript (Deno)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from 'npm:windmill-client@1.318.0';
```

</TabItem>
<TabItem value="bun" label="TypeScript (Bun)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from 'windmill-client';
```

</TabItem>
</Tabs>

## Usage

The TypeScript client provides several functions that you can use to interact with the Windmill platform. Here's an example of how to use the client to get a resource from Windmill:

<Tabs className="unique-tabs">
<TabItem value="deno" label="TypeScript (Deno)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from 'npm:windmill-client@1.318.0';

export async function main() {
	let x = await wmill.getResource('u/user/name');
}
```

</TabItem>
<TabItem value="bun" label="TypeScript (Bun)" attributes={{className: "text-xs p-4 !mt-0 !ml-0"}}>

```ts
import * as wmill from 'windmill-client@1.147.3';

export async function main() {
	let x = await wmill.getResource('u/user/name');
}
```

</TabItem>
</Tabs>

In the example above, the `getResource` function is used to retrieve a resource with the path `'u/user/name'` from the Windmill platform. The returned resource can be further processed or used as needed in your application.

## See Also

- [Documentation Index](./COMPASS.md)
