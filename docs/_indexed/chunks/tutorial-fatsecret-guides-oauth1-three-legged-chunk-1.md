---
doc_id: tutorial/fatsecret/guides-oauth1-three-legged
chunk_id: tutorial/fatsecret/guides-oauth1-three-legged#chunk-1
heading_path: ["FatSecret Platform API - 3-Legged OAuth"]
chunk_type: prose
tokens: 232
summary: "<!--"
---

<!--
<doc_metadata>
  <type>tutorial</type>
  <category>api</category>
  <title>FatSecret Platform API - 3-Legged OAuth</title>
  <description>3-legged OAuth allows your application to access user-specific data on their behalf. This is required for food diaries, weight tracking, and exercise logs.</description>
  <created_at>2026-01-02T19:55:26.867970</created_at>
  <updated_at>2026-01-02T19:55:26.867970</updated_at>
  <language>en</language>
  <sections count="8">
    <section name="Overview" level="2"/>
    <section name="Step 1: Obtaining a Request Token" level="2"/>
    <section name="Step 2: User Authorization" level="2"/>
    <section name="Step 3: Exchanging for an Access Token" level="2"/>
    <section name="Using the Access Token" level="2"/>
    <section name="Complete Flow Example (Python)" level="2"/>
    <section name="Token Lifetime" level="2"/>
    <section name="Security Considerations" level="2"/>
  </sections>
  <features>
    <feature>complete_flow_example_python</feature>
    <feature>overview</feature>
    <feature>python___init__</feature>
    <feature>python__sign_request</feature>
    <feature>python_get_access_token</feature>
    <feature>python_get_authorization_url</feature>
    <feature>python_get_request_token</feature>
    <feature>security_considerations</feature>
    <feature>step_1_obtaining_a_request_token</feature>
    <feature>step_2_user_authorization</feature>
    <feature>step_3_exchanging_for_an_access_token</feature>
    <feature>token_lifetime</feature>
    <feature>using_the_access_token</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
  </dependencies>
  <examples count="10">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>tutorial,beginner,oauth,api,fatsecret</tags>
</doc_metadata>
-->

# FatSecret Platform API - 3-Legged OAuth

> **Context**: 3-legged OAuth allows your application to access user-specific data on their behalf. This is required for food diaries, weight tracking, and exercise 

3-legged OAuth allows your application to access user-specific data on their behalf. This is required for food diaries, weight tracking, and exercise logs.

**Note:** 3-legged OAuth is only available with OAuth 1.0.
