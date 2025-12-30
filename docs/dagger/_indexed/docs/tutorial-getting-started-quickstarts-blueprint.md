---
id: tutorial/getting-started/quickstarts-blueprint
title: "Use a Blueprint Module"
category: tutorial
tags: ["tutorial", "git", "module", "function", "container"]
---

# Use a Blueprint Module

> **Context**: A Dagger module may reference another module as its blueprint.


A Dagger module may reference another module as its blueprint.

Using a module as a blueprint means that your module will automatically have the functions of the blueprint module directly callable. This is great for platform teams daggerizing many software components with identical stacks because each project does not need to reimplement the same code in every project, they simply install the blueprint.

When you use a blueprint module, the context directory will automatically be your repository rather than the blueprint's repository.

This quickstart will guide you through using a blueprint module in an example application.

## Requirements

This quickstart will take you approximately 5 minutes to complete.

Before beginning, ensure that:

- you have [installed the Dagger CLI](./ops-getting-started-installation.md).
- you know [the basics of Dagger](/getting-started/quickstarts/basics).
- you have Git and a container runtime installed on your system and running.
- you have a GitHub account (optional, only if configuring Dagger Cloud)

## Get the example application

The example application is a skeleton Vue framework application that returns a "Hello from Dagger!" welcome page. Create a Github repository from the [hello-dagger-template](https://github.com/dagger/hello-dagger-template) and set it as the current working directory.

With the `gh` CLI:

```bash
gh repo create hello-dagger --template dagger/hello-dagger-template --public --clone
cd hello-dagger
```

## Configure Dagger Cloud (optional)

> **Important:** This step is optional and will create a Dagger Cloud account, which is free of charge for a single user.

Dagger Cloud is an online visualization tool for Dagger workflows. Create a new Dagger Cloud account by running `dagger login`:

```bash
dagger login
```

## Initialize a Dagger module with a blueprint

Create a new Dagger module using `dagger init`, but using an existing module as a blueprint:

```bash
dagger init --blueprint=github.com/kpenfound/blueprints/hello-dagger
```

The `--blueprint` flag means the new module will use the Dagger module at [github.com/kpenfound/blueprints/hello-dagger](https://github.com/kpenfound/blueprints/tree/main/hello-dagger) as a blueprint.

See what tools have been installed:

```bash
dagger functions
```

You will see:

```
Name        Description
build       Build the application container
build-env   Build a ready-to-use development environment
publish     Publish the application container after building and testing it on-the-fly
test        Return the result of running unit tests
```

Try running the test function:

```bash
dagger call test
```

## Next steps

Congratulations! You've installed your first blueprint module with Dagger.

Now you have the tools to successfully take the next step: [adopting Dagger in your project](/reference/best-practices/adopting).

## See Also

- [installed the Dagger CLI](./ops-getting-started-installation.md)
