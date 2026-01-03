---
id: concept/tandoor/permissions
title: "Permissions"
category: concept
tags: ["permissions", "rust", "tandoor", "concept"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>Permissions</title>
  <description>!!! danger &quot;WIP&quot; This application was developed for private use in a trusted environment. Due to popular demand a basic permission system has been added. It does its job protecting the most critical p</description>
  <created_at>2026-01-02T19:55:27.335208</created_at>
  <updated_at>2026-01-02T19:55:27.335208</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Permission levels" level="2"/>
    <section name="Creating User accounts" level="2"/>
    <section name="Managing Permissions" level="2"/>
  </sections>
  <features>
    <feature>creating_user_accounts</feature>
    <feature>managing_permissions</feature>
    <feature>permission_levels</feature>
  </features>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>permissions,rust,tandoor,concept</tags>
</doc_metadata>
-->

# Permissions

> **Context**: !!! danger "WIP" This application was developed for private use in a trusted environment. Due to popular demand a basic permission system has been add

!!! danger "WIP"
    This application was developed for private use in a trusted environment.
    Due to popular demand a basic permission system has been added. 
    It does its job protecting the most critical parts of the application, but it is **not yet recommended** to 
    give accounts to completely untrusted users.
    Work is done to improve the permission system, but it's not yet fully done and tested.

## Permission levels
The following table roughly defines the capabilities of each role

| Group            | Capabilities                                                 |
| ---------------- | ------------------------------------------------------------ |
| logged in user   | Can do almost nothing without a group.                        |
| guest            | - Search and view recipes<br />- write comments <br />- change user settings (e.g. language, theme, password) |
| user             | Can do basically everything except for what admins can do    |
| admin            | - Create, edit and delete external storage<br />- Create, edit and delete synced paths |
| django superuser | Ignores all permission checks and can access admin interface |

## Creating User accounts

!!! warning
    Users without groups cannot do anything. Make sure to assign them a group!

You can either create new users through the admin interface or by sending them invite links.

Invite links can be generated on the System page. If you specify a username during the creation of the link 
the person using it won't be able to change that name.

## Managing Permissions
Management of permissions can currently only be achieved through the django admin interface.

!!! warning
    Please do not rename the groups as this breaks the permission system.



## See Also

- [Documentation Index](./COMPASS.md)
