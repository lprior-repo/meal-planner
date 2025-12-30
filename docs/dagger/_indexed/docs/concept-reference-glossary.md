---
id: concept/reference/glossary
title: "Glossary"
category: concept
tags: ["ci", "module", "function", "container", "concept"]
---

# Glossary

> **Context**: Key terms and concepts used in Dagger documentation.


Key terms and concepts used in Dagger documentation.

## Cache Volume

A Cache Volume is a persistent storage volume used to speed up operations in Dagger by caching intermediate results. Cache volumes are particularly useful for operations like dependency installation, where the same dependencies might be needed across multiple builds.

## Container

A Container is a core type in Dagger that represents a lightweight, standalone, and executable package of software that includes everything needed to run an application. Containers are immutable in Dagger, with each operation creating a new Container instance.

## Custom Application

A Custom Application is a Dagger SDK embedded directly into your application code. This allows you to use Dagger features such as container operations, secret management, and more, without needing to create a separate Dagger module.

## Custom Runner

A Custom Runner is a Dagger Engine that is configured to run in a specific environment, such as Docker, Kubernetes, or Podman.

## Dagger API

The Dagger API is a unified interface for composing Dagger workflows. It provides a set of core functions and core types for creating and managing application delivery workflows.

## Dagger CLI

The Dagger CLI is a command-line tool that allows you to interact with the Dagger API, call Dagger Functions, and manage Dagger modules.

## Dagger Cloud

Dagger Cloud is a browser-based interface focused on tracing and debugging Dagger workflows. It provides visualization tools for operational telemetry.

## Dagger Engine

The Dagger Engine is the core component of the Dagger platform that executes workflows. It manages the execution of Dagger Functions and ensures that they are run in the correct order.

## Dagger Function

A Dagger Function is a reusable block of code that can be executed within a Dagger workflow. Functions can take inputs, perform actions, and return outputs.

## Dagger Module

A Dagger module is a collection of Dagger Functions that can be used together to perform a specific task or set of tasks.

## Dagger SDK

A Dagger SDK is a software development kit that provides the tools and libraries needed to create Dagger modules and Functions in a specific programming language. SDKs are available for Go, TypeScript, PHP, and Python.

## Dagger Shell

The Dagger Shell is an interactive client for the Dagger API, giving you access to typed objects, built-in documentation, and the ability to execute Dagger Functions.

## Daggerverse

The Daggerverse is a free service run by Dagger that indexes all publicly available Dagger modules and Dagger Functions.

## Directory

A Directory is a core type in Dagger that represents a collection of files and subdirectories.

## Function Chaining

Function Chaining is a core feature of Dagger that allows you to connect multiple functions together in sequence, with the output of one function becoming the input to the next function.

## GitRepository

A GitRepository is a core type in Dagger that represents a Git repository. It provides functions for cloning, fetching, and manipulating Git repositories.

## Runner

A Runner is the backend component of the Dagger Engine that executes containers specified by pipelines.

## Secret

A Secret is a core type in Dagger that represents sensitive information, such as API keys, passwords, or certificates. Secrets are handled securely.

## Service

A Service is a core type in Dagger that represents a network service exposed by a container.

## Session

A Session in Dagger is a temporary environment that serves the GraphQL API to clients, manages the synchronization of local directories into pipeline containers, and handles the proxying of local sockets.

## See Also

- [Documentation Overview](./COMPASS.md)
