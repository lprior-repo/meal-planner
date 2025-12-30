---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-1
heading_path: ["Windmill Deployment Guide"]
chunk_type: prose
tokens: 163
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>deployment</category>
  <title>Windmill Deployment Guide</title>
  <description>Complete guide for deploying meal-planner Windmill infrastructure including resources, variables, schedules, OAuth, and monitoring</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="9">
    <section name="Prerequisites" level="1"/>
    <section name="Windmill Setup" level="1"/>
    <section name="Resources Configuration" level="1"/>
    <section name="Variables and Secrets" level="1"/>
    <section name="Schedules" level="1"/>
    <section name="OAuth Configuration" level="1"/>
    <section name="Database Migrations" level="1"/>
    <section name="Monitoring and Alerting" level="1"/>
    <section name="Runbook: Common Issues" level="1"/>
  </sections>
  <features>
    <feature>wmill_cli</feature>
    <feature>windmill_resources</feature>
    <feature>oauth</feature>
    <feature>schedules</feature>
    <feature>monitoring</feature>
    <feature>troubleshooting</feature>
  </features>
  <dependencies>
    <dependency type="tool">wmill_cli</dependency>
    <dependency type="service">postgres</dependency>
    <dependency type="service">tandoor</dependency>
    <dependency type="service">fatsecret</dependency>
  </dependencies>
  <code_examples count="15</code_examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>30</estimated_reading_time>
  <tags>windmill,deployment,devops,infrastructure,monitoring,oauth,schedules</tags>
</doc_metadata>
-->

# Windmill Deployment Guide

> **Context**: <!-- <doc_metadata> <type>guide</type> <category>deployment</category> <title>Windmill Deployment Guide</title> <description>Complete guide for deploy

This guide covers deploying the meal-planner Windmill infrastructure, including resources, variables, schedules, OAuth configuration, database migrations, monitoring, and troubleshooting.

---
