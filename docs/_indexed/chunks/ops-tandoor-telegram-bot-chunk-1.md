---
doc_id: ops/tandoor/telegram-bot
chunk_id: ops/tandoor/telegram-bot#chunk-1
heading_path: ["Telegram Bot"]
chunk_type: prose
tokens: 252
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>Telegram Bot</title>
  <description>The telegram bot is meant to simplify certain interactions with Tandoor. It is currently very basic but might be expanded in the future.</description>
  <created_at>2026-01-02T19:55:27.278207</created_at>
  <updated_at>2026-01-02T19:55:27.278207</updated_at>
  <language>en</language>
  <sections count="2">
    <section name="Shopping Bot" level="2"/>
    <section name="Resetting" level="3"/>
  </sections>
  <features>
    <feature>resetting</feature>
    <feature>shopping_bot</feature>
  </features>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>telegram,tandoor,operations</tags>
</doc_metadata>
-->

# Telegram Bot

> **Context**: The telegram bot is meant to simplify certain interactions with Tandoor. It is currently very basic but might be expanded in the future.

The telegram bot is meant to simplify certain interactions with Tandoor.
It is currently very basic but might be expanded in the future.

!!! warning "Experimental"
    This feature is considered experimental. You can use it and it should not break anything but you might be 
    required to update your configuration in the future.
    The setup is also definitely not user-friendly, this will likely improve if the feature is well-received/expanded.

!!! info "Public IP/Domain"
    To use the Telegram Bot you will need an installation that is accessible from the outside, otherwise telegram can't send messages.
    This could be circumvented using the polling API but this is currently not implemented.
