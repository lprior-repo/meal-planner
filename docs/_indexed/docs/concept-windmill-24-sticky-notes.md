---
id: concept/windmill/24-sticky-notes
title: "Sticky notes"
category: concept
tags: ["windmill", "sticky", "concept"]
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

## Creating sticky notes

### Free notes

Create free notes to add general documentation or comments anywhere on the flow canvas.

**Method 1: Toolbar button**

1. Click the sticky note button in the top toolbar
2. Drag and drop on the canvas to position the note

**Method 2: Context menu**

1. Right-click anywhere on the canvas
2. Select "Add sticky note" from the context menu

![Sticky notes interface](../assets/flows/sticky_notes_interface.png 'Sticky notes interface - toolbar with sticky note button and toggle')

### Group notes

Group notes attach to multiple selected nodes to document specific workflow sections or logical blocks.

**Creating group notes:**

1. Enter selection mode by clicking the cursor/hand button in the top-right of the flow pane
2. Select multiple nodes by clicking and dragging or clicking individual nodes while holding Shift
3. Click "Create group note" button that appears when nodes are selected

**Selection mode tips:**

- In selection mode: Hold Ctrl/Cmd to temporarily pan the canvas
- In pan mode: Hold Ctrl/Cmd to temporarily select nodes

![Group note example](../assets/flows/group_note_example.png 'Group note attached to multiple flow nodes')

## Managing sticky notes

### Editing content

Double-click any note to edit its content. Notes support GitHub-flavored Markdown (GHMd) for formatting.

### Customizing appearance

Each note has an action bar in the top-right corner with the following options:

- **Color picker**: Change note color (supports both light and dark themes)
- **Lock icon**: Lock the note to prevent accidental editing or movement
- **Delete button**: Remove the note from the flow

![Sticky note action bar](../assets/flows/sticky_note_action_bar.png 'Action bar with color picker, lock, and delete buttons')

### Positioning notes

Drag notes freely around the canvas to position them where most relevant. Locked notes cannot be moved until unlocked.

## Hiding and showing notes

Use the toggle button in the top-left of the flow pane to hide or show all sticky notes. This is useful when you need a clean view of the flow logic or when presenting to stakeholders.

## Free note example

Free notes are ideal for:

- General flow documentation
- TODO items for future improvements
- Warnings or important considerations
- Links to related resources or documentation

![Free note example](../assets/flows/free_note_example.png 'Standalone free note with sample content')

## Working with group notes

Group notes automatically maintain their association with the selected nodes. However, there are some limitations when editing the grouped nodes:

**To modify nodes in a group note:**

- **Option 1**: Delete the note, make your node changes, then create a new group note with the updated selection
- **Option 2**: Edit the flow directly in YAML/JSON format to modify the grouped nodes while preserving the note

Group notes are particularly useful for:

- Documenting complex logic blocks
- Explaining error handling sections
- Describing data transformation steps
- Marking deprecated or experimental features

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		color="teal"
		title="Flow editor components"
		description="Details on the flow editor's major components including toolbar and canvas features."
		href="/docs/flows/editor_components"
	/>
	<DocCard
		color="teal"
		title="Testing flows"
		description="Iterate quickly and get control on your flow testing."
		href="/docs/flows/test_flows"
	/>
</div>


## See Also

- [Sticky notes interface](../assets/flows/sticky_notes_interface.png 'Sticky notes interface - toolbar with sticky note button and toggle')
- [Group note example](../assets/flows/group_note_example.png 'Group note attached to multiple flow nodes')
- [Sticky note action bar](../assets/flows/sticky_note_action_bar.png 'Action bar with color picker, lock, and delete buttons')
- [Free note example](../assets/flows/free_note_example.png 'Standalone free note with sample content')
