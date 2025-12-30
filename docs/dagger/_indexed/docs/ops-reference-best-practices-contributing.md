---
id: ops/reference/best-practices-contributing
title: "Contributing to Dagger"
category: ops
tags: ["ops", "github", "git", "test", "ai"]
---

# Contributing to Dagger

> **Context**: Guide for contributing to Dagger's open source repository.


Guide for contributing to Dagger's open source repository.

## Initial Setup

### 1. Join the Discord

[Join our Discord server](https://discord.gg/UhXqKz7SRM) - it's the beating heart of the community.

### 2. Install Dagger

Install the [latest stable release](http://dagger.io/install).

### 3. Install Changie

[Install Changie](https://changie.dev/guide/installation/) for managing release notes.

### 4. Git Setup

```bash
## Clone your fork
git clone git@github.com:$YOUR_GITHUB_USER/dagger.git

## Add the upstream repository
git remote add upstream git@github.com:dagger/dagger.git
```

## Contribution Workflow

### 1. Claim an issue

Find or [report an issue on GitHub](https://github.com/dagger/dagger/issues). Write a comment to declare your intention to contribute a solution.

### 2. Communicate

For bigger contributions, communicate upfront your plan and design. Communicate early and often!

### 3. Develop

#### Manual testing

```bash
dagger call playground terminal
```

#### Integration testing

- Run all core tests: `dagger call test all`
- Run available core tests: `dagger call test list`
- Run SDK tests: `dagger call test-sdks`

#### Linting

```bash
dagger call lint
```

#### Local docs server

```bash
dagger -m docs call server up
```

### 4. Prepare your pull request

- Generate API docs: `dagger call generate`
- Run all linters: `dagger call lint`
- Add a release note: `changie new`
- Sign-off commits with `git commit -s`

### 5. Submit your pull request

Push your feature branch to your fork and create a new pull request.

### 6. Review process

- A maintainer will review your pull request
- Make changes if requested
- Rebase on top of latest `main` if there are conflicts

## See Also

- [Documentation Overview](./COMPASS.md)
