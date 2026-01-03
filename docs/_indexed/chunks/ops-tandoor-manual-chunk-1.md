---
doc_id: ops/tandoor/manual
chunk_id: ops/tandoor/manual#chunk-1
heading_path: ["Manual installation instructions"]
chunk_type: prose
tokens: 287
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>Manual installation instructions</title>
  <description>These instructions are inspired from a standard django/gunicorn/postgresql instructions ([for example](https://www.digitalocean.com/community/tutorials/how-to-set-up-django-with-postgres-nginx-and-gun</description>
  <created_at>2026-01-02T19:55:27.298431</created_at>
  <updated_at>2026-01-02T19:55:27.298431</updated_at>
  <language>en</language>
  <sections count="13">
    <section name="Prerequisites" level="2"/>
    <section name="Just use one of these possibilites!" level="3"/>
    <section name="... as root" level="2"/>
    <section name="... no root privileges" level="2"/>
    <section name="Install postgresql requirements" level="3"/>
    <section name="Install LDAP requirements" level="3"/>
    <section name="Install project requirements" level="3"/>
    <section name="Setup postgresql" level="2"/>
    <section name="Initialize the application" level="2"/>
    <section name="Setup web services" level="2"/>
  </sections>
  <features>
    <feature>_as_root</feature>
    <feature>_no_root_privileges</feature>
    <feature>gunicorn</feature>
    <feature>initialize_the_application</feature>
    <feature>install_ldap_requirements</feature>
    <feature>install_postgresql_requirements</feature>
    <feature>install_project_requirements</feature>
    <feature>just_use_one_of_these_possibilites</feature>
    <feature>nginx</feature>
    <feature>prerequisites</feature>
    <feature>setup_postgresql</feature>
    <feature>setup_web_services</feature>
    <feature>updating</feature>
  </features>
  <dependencies>
    <dependency type="service">postgres</dependency>
    <dependency type="service">postgresql</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses"></entity>
  </related_entities>
  <examples count="13">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>manual,advanced,operations,tandoor,sql</tags>
</doc_metadata>
-->

# Manual installation instructions

> **Context**: These instructions are inspired from a standard django/gunicorn/postgresql instructions ([for example](https://www.digitalocean.com/community/tutorial

These instructions are inspired from a standard django/gunicorn/postgresql instructions ([for example](https://www.digitalocean.com/community/tutorials/how-to-set-up-django-with-postgres-nginx-and-gunicorn-on-ubuntu-16-04))

!!! warning
    Make sure to use at least Python 3.12 or higher, and ensure that `pip` is associated with Python 3. Depending on your system configuration, using `python` or `pip` might default to Python 2. Make sure your machine has at least 2048 MB of memory; otherwise, the `yarn build` process may fail with the error: `FATAL ERROR: Reached heap limit - Allocation failed: JavaScript heap out of memory`.

!!! warning
    These instructions are **not** regularly reviewed and might be outdated.
