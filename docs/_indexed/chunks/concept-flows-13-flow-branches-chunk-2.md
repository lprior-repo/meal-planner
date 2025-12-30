---
doc_id: concept/flows/13-flow-branches
chunk_id: concept/flows/13-flow-branches#chunk-2
heading_path: ["Branches", "Branch one"]
chunk_type: prose
tokens: 222
summary: "Branch one"
---

## Branch one

A branch one is a special type of step that allows you to execute a branch if a condition is true. If the condition is false, the default branch will be executed. If several branches are true, the first one will execute. Each branch is a flow.

Clicking on one branch will open the branch editor. You can configure the:

- **Summary**: gives a name to the branch, useful when several branches. By default Branch 1, 2, 3...
- **Predicate expression**: the expression that will be evaluated to determine if the branch should be executed. It can be simple `true`/`false` but also comparison operators (`results.c.command === 'email'`, `flow_input.number >= 2` etc.)

![Branch one step](../assets/flows/flow_branch_one.png.webp)

_Example of branches to [handle a Slackbot](/blog/handler-slack-commands)_.

All the predicates can also be configured in the `Run one branch` step (parent box). The predicates are evaluated in the order they are defined. The first predicate that evaluates to true will be executed. If no predicate evaluates to true, the default branch will be executed.
