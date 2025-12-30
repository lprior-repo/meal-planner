# How it works

## Languages

Although moon is currently focusing on the JavaScript ecosystem, our long-term vision is to be a multi-language task runner and monorepo management tool.

## Project graph

The project graph is a representation of all configured projects in the workspace and their relationships between each other.

## Task graph

The task graph is a representation of all configured tasks in the workspace and their relationships between each other.

## Action graph

When you run a task on the command line, we generate an action graph to ensure dependencies of tasks have ran before running run the primary task.
