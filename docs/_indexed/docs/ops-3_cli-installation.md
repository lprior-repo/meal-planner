---
id: ops/3_cli/installation
title: "Installation"
category: ops
tags: ["operations", "3_cli", "windmill", "installation"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>cli</category>
  <title>Windmill CLI Installation</title>
  <description>Install and configure Windmill CLI</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Installation" level="1"/>
    <section name="Upgrade wmill" level="2"/>
    <section name="Completion" level="2"/>
    <section name="Bash" level="3"/>
    <section name="Zsh" level="3"/>
    <section name="Fish" level="3"/>
  </sections>
  <features>
    <feature>wmill_cli</feature>
    <feature>installation</feature>
    <feature>shell_completions</feature>
    <feature>upgrade</feature>
  </features>
  <dependencies>
    <dependency type="platform">node</dependency>
  </dependencies>
  <examples count="3">
    <example>Install wmill CLI</example>
    <example>Enable bash completions</example>
    <example>Upgrade to latest version</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>windmill,cli,wmill,install,node,npm,upgrade,completions,bash,zsh,fish</tags>
</doc_metadata>
-->

# Installation

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>cli</category> <title>Windmill CLI Installation</title> <description>Install and configure Windmi

<iframe
    style={{ aspectRatio: '16/9' }}
    src="https://www.youtube.com/embed/TXtmLrToxoI"
    title="YouTube video player"
    frameBorder="0"
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
    allowFullScreen
    className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br/>

To install the wmill CLI:

```bash
npm install -g windmill-cli
```text

Node version must greater than v20.

Also, to punch through some networking layers like Cloudflare Tunnel, you might need some custom headers. You just need to use the HEADERS env variable:

```
export HEADERS=header_key:header_value,header_key2:header_value2
```text

Verify that the installation was successful by running the following command:

```bash
wmill --version
```text

If the installation was successful, you should see the version of wmill that you just installed.

## Upgrade wmill

To upgrade your wmill installation to the latest version, run the following command:

```bash
wmill upgrade
```text

## Completion

The CLI comes with built-in completions for various shells. Use the following instructions to enable completions for your preferred shell.

### Bash

To enable bash completions, add the following line to your ~/.bashrc:

```bash
source <(wmill completions bash)
```text

### Zsh

To enable zsh completions, add the following line to your ~/.zshrc:

```bash
source <(wmill completions zsh)
```text

### Fish

To enable fish completions, add the following line to your ~/.config/fish/config.fish:

```bash
source (wmill completions fish | psub)
```


## See Also

- [Documentation Index](./COMPASS.md)
