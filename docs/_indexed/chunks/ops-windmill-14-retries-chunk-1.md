---
doc_id: ops/windmill/14-retries
chunk_id: ops/windmill/14-retries#chunk-1
heading_path: ["Retries"]
chunk_type: prose
tokens: 510
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Retries</title>
  <description>&lt;!-- &lt;doc_metadata&gt; &lt;type&gt;reference&lt;/type&gt; &lt;category&gt;flows&lt;/category&gt; &lt;title&gt;Retries&lt;/title&gt; &lt;description&gt;Configure retry logic for flow steps with constant delays or exponential backoff&lt;/description&gt;</description>
  <created_at>2026-01-02T19:55:27.949725</created_at>
  <updated_at>2026-01-02T19:55:27.949725</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Constant retries" level="2"/>
    <section name="Exponential backoff enabled" level="2"/>
    <section name="Continue on error with error as step&apos;s return" level="2"/>
  </sections>
  <features>
    <feature>constant_retries</feature>
    <feature>exponential_backoff_enabled</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
    <dependency type="feature">meta/windmill/index-33</dependency>
    <dependency type="feature">concept/windmill/13-flow-branches</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../core_concepts/19_rich_display_rendering/index.mdx</entity>
    <entity relationship="uses">/blog/stantt-case-study</entity>
    <entity relationship="uses">../assets/flows/constant_retries.png.webp</entity>
    <entity relationship="uses">../assets/flows/exponential_delay.png.webp</entity>
    <entity relationship="uses">./13_flow_branches.md</entity>
    <entity relationship="uses">../assets/flows/continue_on_error1.png &quot;Continue on error step&quot;</entity>
    <entity relationship="uses">../assets/flows/continue_on_error2.png &quot;Continue on error flow&quot;</entity>
  </related_entities>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,operations,retries</tags>
</doc_metadata>
-->

<!--
<doc_metadata>
  <type>reference</type>
  <category>flows</category>
  <title>Retries</title>
  <description>Configure retry logic for flow steps with constant delays or exponential backoff</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Constant retries" level="2"/>
    <section name="Exponential backoff enabled" level="2"/>
    <section name="Continue on error with error as step's return" level="2"/>
  </sections>
  <features>
    <feature>retries</feature>
    <feature>exponential_backoff</feature>
    <feature>constant_retry</feature>
    <feature>error_continuation</feature>
  </features>
  <dependencies>
    <dependency type="feature">error_handler</dependency>
    <dependency type="feature">flow_branches</dependency>
  </dependencies>
  <examples count="3">
    <example>API requests</example>
    <example>Payment processing</example>
    <example>Batch processing</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>5</estimated_reading_time>
  <tags>windmill,retries,error-handling,exponential-backoff,constant-retry</tags>
</doc_metadata>
-->

# Retries

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>flows</category> <title>Retries</title> <description>Configure retry logic for flow steps with co

Steps within a flow can be re-tried in case of error. This feature is useful to keep a flow trying to execute even if a step momentarily failed.

<video
    className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
    autoPlay
    loop
    controls
    id="main-video"
    src="/videos/retries_example.mp4"
/>

<br/>

If defined, upon error this step will be retried with a delay and a maximum number of attempts as defined below. If both static and exponential delay is defined, the static delay attempts are tried before the exponential ones.

Note that errors have a [specific shape](./meta-windmill-index-33.md#error).

From a single flow, this feature can for example help you with:

- **API requests**: Retry failed API calls due to temporary server issues or network timeouts every 5 minutes, for a maximum of 5 attempts, ensuring eventual data retrieval or synchronization with third-party services.
- **Payment processing**: Try again failed transactions caused by temporary issues with the payment gateway or the customer's bank for up to 3 attempts and each time clocked by longer delay (thanks to exponential backoff), reducing the likelihood of lost sales.
- **[Batch processing](/blog/stantt-case-study)**: Reattempt failed batch processing jobs caused by temporary resource constraints or server issues every 30 minutes, for a maximum of 6 attempts, ensuring that all tasks are eventually completed.

As well as many other examples (inventory synchronization, data backups, file uploads, scraping etc.)
