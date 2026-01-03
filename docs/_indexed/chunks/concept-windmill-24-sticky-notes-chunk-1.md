---
doc_id: concept/windmill/24-sticky-notes
chunk_id: concept/windmill/24-sticky-notes#chunk-1
heading_path: ["Sticky notes"]
chunk_type: prose
tokens: 280
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Sticky notes</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;;</description>
  <created_at>2026-01-02T19:55:27.973731</created_at>
  <updated_at>2026-01-02T19:55:27.973731</updated_at>
  <language>en</language>
  <sections count="10">
    <section name="Creating sticky notes" level="2"/>
    <section name="Free notes" level="3"/>
    <section name="Group notes" level="3"/>
    <section name="Managing sticky notes" level="2"/>
    <section name="Editing content" level="3"/>
    <section name="Customizing appearance" level="3"/>
    <section name="Positioning notes" level="3"/>
    <section name="Hiding and showing notes" level="2"/>
    <section name="Free note example" level="2"/>
    <section name="Working with group notes" level="2"/>
  </sections>
  <features>
    <feature>creating_sticky_notes</feature>
    <feature>customizing_appearance</feature>
    <feature>editing_content</feature>
    <feature>free_note_example</feature>
    <feature>free_notes</feature>
    <feature>group_notes</feature>
    <feature>hiding_and_showing_notes</feature>
    <feature>managing_sticky_notes</feature>
    <feature>positioning_notes</feature>
    <feature>working_with_group_notes</feature>
  </features>
  <related_entities>
    <entity relationship="uses">../assets/flows/sticky_notes_interface.png &apos;Sticky notes interface - toolbar with sticky note button and toggle&apos;</entity>
    <entity relationship="uses">../assets/flows/group_note_example.png &apos;Group note attached to multiple flow nodes&apos;</entity>
    <entity relationship="uses">../assets/flows/sticky_note_action_bar.png &apos;Action bar with color picker, lock, and delete buttons&apos;</entity>
    <entity relationship="uses">../assets/flows/free_note_example.png &apos;Standalone free note with sample content&apos;</entity>
  </related_entities>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,sticky,concept</tags>
</doc_metadata>
-->

import DocCard from '@site/src/components/DocCard';

# Sticky notes

> **Context**: import DocCard from '@site/src/components/DocCard';

Sticky notes allow you to annotate flows with documentation, comments, and organizational information directly on the flow canvas. Notes help document workflow logic, add TODOs, or explain complex sections to team members.

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/sticky_notes_intro.mp4"
/>

<br />

There are two types of sticky notes:

- **Free notes**: Can be placed anywhere on the canvas for general comments or documentation
- **Group notes**: Attached to a selection of nodes to document specific workflow sections
