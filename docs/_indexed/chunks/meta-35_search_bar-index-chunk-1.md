---
doc_id: meta/35_search_bar/index
chunk_id: meta/35_search_bar/index#chunk-1
heading_path: ["Search bar"]
chunk_type: prose
tokens: 139
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Search bar

> **Context**: import DocCard from '@site/src/components/DocCard';

Every workspace has a Search bar to navigate through it.

![Search bar](./search_bar.png "Search bar")

It can be triggered with shortcut `Ctrl + K` & `⌘k` on Mac, or with Search button from sidebar. From here you can select from the options with the mouse or browse with the arrow keys.

![Search button](./search_button.png "Search button")

Only [Superadmins, Admins & Developers](./meta-16_roles_and_permissions-index.md#roles-in-windmill) (not Operators) have access to this feature.

It can go to several pages:
- Home
- [Runs](./meta-5_monitor_past_and_future_runs-index.md)
- [Variables](./meta-2_variables_and_secrets-index.md)
- [Resources](./meta-3_resources_and_types-index.md)
- [Schedules](./meta-1_scheduling-index.md)

<video
  className="border-2 rounded-xl object-cover w-full h-full dark:border-gray-800"
  autoPlay
  loop
  controls
  src="/videos/search_bar.mp4"
/>
