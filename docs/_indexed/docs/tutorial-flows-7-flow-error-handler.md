---
id: tutorial/flows/7-flow-error-handler
title: "Error handler"
category: tutorial
tags: ["error", "beginner", "flows", "tutorial"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>flows</category>
  <title>Error Handler</title>
  <description>Special flow step executed when an error occurs in flow</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="1">
    <section name="Error handler" level="1"/>
  </sections>
  <features>
    <feature>error_handler</feature>
    <feature>retries</feature>
  </features>
  <dependencies>
    <dependency type="feature">retries</dependency>
    <dependency type="feature">flow_branches</dependency>
  </dependencies>
  <examples count="2">
    <example>Slack error handler</example>
    <example>Discord error handler</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>windmill,error,handler,flow,step,retry,fail,slack,discord</tags>
</doc_metadata>
-->

# Error handler

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>flows</category> <title>Error Handler</title> <description>Special flow step executed when an err

The error handler is a special flow step that is executed when an error occurs in the flow.

If defined, the error handler will take as input the result of the step that errored (which has its error in the 'error field').

<video
    className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
    autoPlay
    loop
    controls
    id="main-video"
    src="/videos/error_handler.mp4"
/>

<br/>

Steps are retried until they succeed, or until the maximum number of retries defined for that spec is reached, at which point the error handler is called.

You can write error handler scripts in:

- [Python](./meta-2_python_quickstart-index.md)
- [TypeScript](./meta-1_typescript_quickstart-index.md)
- [Go](./meta-3_go_quickstart-index.md)

On the Hub, two examples of error handlers are provided:

- [Slack error handler](https://hub.windmill.dev/scripts/slack/1525/send-error-to-slack-channel-slack): sends a message to a Slack channel when an error occurs.
- [Discord error handler](https://hub.windmill.dev/scripts/discord/1523/send-the-error-to-discord-discord): sends a message to a Discord channel when an error occurs.

:::info Example

For instance, when building a workflow to [automatically populate a CRM details from an email](https://www.windmill.dev/blog/automatically-populate-crm), it was decided to set an Error handler to still add the email on the CRM in case of error and not lose the contact's email.

<br/>

![Error handler Example](../assets/flows/error_handler_example.png.webp)

:::


## See Also

- [Python](../getting_started/0_scripts_quickstart/2_python_quickstart/index.mdx)
- [TypeScript](../getting_started/0_scripts_quickstart/1_typescript_quickstart/index.mdx)
- [Go](../getting_started/0_scripts_quickstart/3_go_quickstart/index.mdx)
- [Error handler Example](../assets/flows/error_handler_example.png.webp)
