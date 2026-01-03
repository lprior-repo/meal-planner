---
id: concept/tandoor/ai
title: "Ai"
category: concept
tags: ["tandoor", "concept"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>Ai</title>
  <description>Tandoor has several AI based features. To allow maximum flexibility, you can configure different AI providers and select them based on the task you want to perform. To prevent accidental cost escalati</description>
  <created_at>2026-01-02T19:55:27.255885</created_at>
  <updated_at>2026-01-02T19:55:27.255885</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Default Configuration" level="2"/>
    <section name="Configure AI Providers" level="2"/>
    <section name="AI Log" level="2"/>
  </sections>
  <features>
    <feature>ai_log</feature>
    <feature>configure_ai_providers</feature>
    <feature>default_configuration</feature>
  </features>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>tandoor,concept</tags>
</doc_metadata>
-->

# Ai

> **Context**: Tandoor has several AI based features. To allow maximum flexibility, you can configure different AI providers and select them based on the task you wa

Tandoor has several AI based features. To allow maximum flexibility, you can configure different AI providers and select them based on the task you want to perform.
To prevent accidental cost escalation Tandoor has a robust system of tracking and limiting AI costs.

## Default Configuration
By default the AI features are enabled for every space. Each space has a spending limit of roughly 1 USD per month.
This can be changed using the [configuration variables](https://docs.tandoor.dev/system/configuration/#ai-integration)

You can change these settings any time using the django admin. If you do not care about AI cost you can enter a very high limit or disable cost tracking for your providers.
The limit resets on the first of every month. 

## Configure AI Providers
When AI support is enabled for a space every user in a space can configure AI providers. 
The models shown in the editor have been tested and work with Tandoor. Most other models that can parse images/files and return text should also work. 

Superusers also have the ability to configure global AI providers that every space can use.

## AI Log
The AI Log allows you to track the usage of AI calls. Here you can also see the usage.

## See Also

- [Documentation Index](./COMPASS.md)
