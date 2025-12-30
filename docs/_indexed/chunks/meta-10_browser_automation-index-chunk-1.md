---
doc_id: meta/10_browser_automation/index
chunk_id: meta/10_browser_automation/index#chunk-1
heading_path: ["Browser automation"]
chunk_type: prose
tokens: 263
summary: "Browser automation"
---

# Browser automation

> **Context**: Windmill makes it easy to perform browser automation tasks, such as testing or web scraping.

Windmill makes it easy to perform browser automation tasks, such as testing or web scraping.

:::info
Not sure what a worker group is? You should probably [read about it first](./meta-9_worker_groups-index.md).
:::

By default, a worker group named `reports` is available which will handle jobs with the `chromium` tag.
Workers assigned to this group will install chromium on start (learn more about [init scripts](./meta-9_worker_groups-index.md#init-scripts)).
You have to set the worker group of at least one worker to `reports`.
There is a sample worker container definition called `windmill_worker_reports` in the `docker-compose.yml` file which you can uncomment to quickly start a worker with the right worker group.

The chromium binary will be available on these workers at `/usr/bin/chromium`.
You will need to disable the sandbox to run it inside windmill workers. 
You can do this by passing the `--no-sandbox` flag. 

:::caution
Running chromium without the sandbox is a security risk. Make sure you trust the website you are visiting.
:::

To run jobs on a chromium-equipped worker, you have to select the `chromium` tag in the settings of the script or flow step.
[Learn how here](./meta-9_worker_groups-index.md).
