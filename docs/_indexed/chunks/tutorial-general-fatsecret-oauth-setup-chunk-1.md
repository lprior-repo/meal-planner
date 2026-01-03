---
doc_id: tutorial/general/fatsecret-oauth-setup
chunk_id: tutorial/general/fatsecret-oauth-setup#chunk-1
heading_path: ["FatSecret OAuth Setup (One-Time)"]
chunk_type: prose
tokens: 201
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>core</category>
  <title>FatSecret OAuth Setup (One-Time)</title>
  <description>Complete the 3-legged OAuth flow once. After this, use `$res:u/admin/fatsecret_oauth` in all scripts.</description>
  <created_at>2026-01-02T19:55:26.821586</created_at>
  <updated_at>2026-01-02T19:55:26.821586</updated_at>
  <language>en</language>
  <sections count="6">
    <section name="Step 1: Get Auth URL" level="2"/>
    <section name="Step 2: Authorize in Browser" level="2"/>
    <section name="Step 3: Exchange Verifier" level="2"/>
    <section name="Step 4: Store in Windmill" level="2"/>
    <section name="Step 5: Verify" level="2"/>
    <section name="Done" level="2"/>
  </sections>
  <features>
    <feature>done</feature>
    <feature>step_1_get_auth_url</feature>
    <feature>step_2_authorize_in_browser</feature>
    <feature>step_3_exchange_verifier</feature>
    <feature>step_4_store_in_windmill</feature>
    <feature>step_5_verify</feature>
  </features>
  <dependencies>
    <dependency type="crate">wmill</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../AGENTS.md</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>tutorial,beginner,fatsecret,oauth</tags>
</doc_metadata>
-->

# FatSecret OAuth Setup (One-Time)

> **Context**: Complete the 3-legged OAuth flow once. After this, use `$res:u/admin/fatsecret_oauth` in all scripts.

Complete the 3-legged OAuth flow once. After this, use `$res:u/admin/fatsecret_oauth` in all scripts.

**For both humans and AI agents**: This doc is self-contained but links to related docs if you need context.

**Prerequisites**: FatSecret developer account with Consumer Key and Secret already stored in `u/admin/fatsecret_api`.
