<!--
<doc_metadata>
  <type>reference</type>
  <category>core_concepts</category>
  <title>Job Debouncing</title>
  <description>Prevents redundant job executions by canceling pending jobs with identical characteristics</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Job debouncing" level="1"/>
    <section name="Debounce delay in seconds" level="2"/>
    <section name="Custom debounce key" level="2"/>
    <section name="Dependency jobs" level="2"/>
    <section name="Job debouncing in Script & Flows" level="2"/>
  </sections>
  <features>
    <feature>job_debouncing</feature>
    <feature>duplicate_prevention</feature>
    <feature>resource_optimization</feature>
    <feature>auto_cancellation</feature>
  </features>
  <dependencies>
    <dependency type="feature">enterprise_edition</dependency>
  </dependencies>
  <examples count="2">
    <example>Prevent duplicate API calls</example>
    <example>Optimize workflow triggers</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>windmill,debounce,cancel,pending,duplicate,jobs,optimization</tags>
</doc_metadata>
-->

# Job debouncing

Job debouncing prevents redundant job executions by canceling pending jobs with identical characteristics when new ones are submitted within a specified time window. This feature helps optimize resource usage and prevents unnecessary duplicate computations.

Job debouncing is a [Cloud plans and Pro Enterprise Self-Hosted](/pricing) only.

Debouncing can be set from the Settings menu. When jobs with matching characteristics are submitted within the debounce window, pending jobs are automatically canceled in favor of the newest one.

The Job debouncing operates globally and across flow runs. It involves two key parameters:

## Debounce delay in seconds

Set in seconds, the time window defines the period during which duplicate jobs are canceled. When a new job arrives within this window with matching characteristics, any pending jobs are canceled.

## Custom debounce key

This parameter is optional. Debounce keys are global, you can have them be workspace specific using the variable `$workspace`. You can also use an argument's value using `$args[name_of_arg]`.

## Dependency jobs

For dependency jobs, debouncing is enabled by default. This prevents redundant dependency computations when multiple jobs require the same dependencies.

## Job debouncing in Script & Flows

### Job debouncing of a script

[Job debouncing of a script](../../script_editor/settings.mdx#debouncing) can be set from the [Settings](../../script_editor/settings.mdx) menu. Pick "Runtime" and then "Debouncing" and define a time window and optionally a custom debounce key.

### Job debouncing of a flow

From the Flow Settings Advanced menu, pick "Debouncing" and define a time window and optionally a custom debounce key.
