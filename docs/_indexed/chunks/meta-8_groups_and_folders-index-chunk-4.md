---
doc_id: meta/8_groups_and_folders/index
chunk_id: meta/8_groups_and_folders/index#chunk-4
heading_path: ["Groups and folders", "Groups and folders together"]
chunk_type: prose
tokens: 170
summary: "Groups and folders together"
---

## Groups and folders together

Groups and folders work together to organize permissions and access control within your workspace. Groups can be included within folders, but folders cannot be nested within groups.

It means that if you want to allow a team to use a given resource, you can save it in a folder, and either add each member of the team as a user in the folder, or add a group containing the whole team to the folder.

:::tip Example of groups and folders used together

For example, you are [building a Slackbot](/blog/handler-slack-commands) and want it to use manipulate some resources. You can add the `g/slack` group (which is automatically created when you [configure Slack on Windmill](../../integrations/slack.mdx) to the desired resource).

<br />

![Groups within folders](./2-groups-within-folders.png 'Groups within folders')

:::
