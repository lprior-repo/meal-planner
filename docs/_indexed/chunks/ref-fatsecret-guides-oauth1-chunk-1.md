---
doc_id: ref/fatsecret/guides-oauth1
chunk_id: ref/fatsecret/guides-oauth1#chunk-1
heading_path: ["FatSecret Platform API - OAuth 1.0 Guide"]
chunk_type: prose
tokens: 185
summary: "<!--"
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>api</category>
  <title>FatSecret Platform API - OAuth 1.0 Guide</title>
  <description>OAuth 1.0 authentication requires signing each request with your credentials.</description>
  <created_at>2026-01-02T19:55:26.871982</created_at>
  <updated_at>2026-01-02T19:55:26.871982</updated_at>
  <language>en</language>
  <sections count="17">
    <section name="Required Parameters" level="2"/>
    <section name="Creating the Signature Base String" level="2"/>
    <section name="1. HTTP Method" level="3"/>
    <section name="2. Base URL" level="3"/>
    <section name="3. Parameter String" level="3"/>
    <section name="Combining Components" level="3"/>
    <section name="Calculating the Signature" level="2"/>
    <section name="1. Create the Signing Key" level="3"/>
    <section name="2. Calculate HMAC-SHA1" level="3"/>
    <section name="3. URL-Encode the Result" level="3"/>
  </sections>
  <features>
    <feature>1_create_the_signing_key</feature>
    <feature>1_http_method</feature>
    <feature>2_base_url</feature>
    <feature>2_calculate_hmac-sha1</feature>
    <feature>3_parameter_string</feature>
    <feature>3_url-encode_the_result</feature>
    <feature>as_authorization_header</feature>
    <feature>as_query_parameters_get</feature>
    <feature>calculating_the_signature</feature>
    <feature>combining_components</feature>
    <feature>common_issues</feature>
    <feature>creating_the_signature_base_string</feature>
    <feature>example_implementation</feature>
    <feature>python</feature>
    <feature>python_calculate_signature</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
  </dependencies>
  <examples count="9">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>api,fatsecret,oauth,reference</tags>
</doc_metadata>
-->

# FatSecret Platform API - OAuth 1.0 Guide

> **Context**: OAuth 1.0 authentication requires signing each request with your credentials.

OAuth 1.0 authentication requires signing each request with your credentials.
