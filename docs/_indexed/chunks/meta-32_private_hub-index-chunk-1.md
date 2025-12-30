---
doc_id: meta/32_private_hub/index
chunk_id: meta/32_private_hub/index#chunk-1
heading_path: ["Private Hub"]
chunk_type: prose
tokens: 397
summary: "Private Hub"
---

# Private Hub

> **Context**: [Windmill Hub](https://hub.windmill.dev/) is the community website of Windmill where you can find and share your Scripts, Flows, Apps and Resource typ

[Windmill Hub](https://hub.windmill.dev/) is the community website of Windmill where you can find and share your Scripts, Flows, Apps and Resource types with every Windmill user. 
The best submissions get approved by the Windmill Team and get integrated directly in the app for everyone to reuse easily.

![Example of Hub scripts suggested in flow editor](./hub_suggested.png "Example of Hub scripts suggested in flow editor")

> Example of Hub scripts suggested in flow editor

<br/>

On [Enterprise Edition](/pricing) and [Whitelabelling](/pricing), you can have your own Private Hub. 
You decide which scripts, flows, apps and resource types are approved and are shared with your Windmill instances, appearing directly in the app.

You can configure your Private Hub using Docker by following the instructions in the [Private Hub repository](https://github.com/windmill-labs/windmillhub-ee-public).
We also provide [values in our Helm chart](https://github.com/windmill-labs/windmill-helm-charts/blob/main/charts/windmill/values.yaml) for including the Private Hub in a Kubernetes cluster.

Once your Private Hub is up and running, you need to change the hub base url field in the core [instance settings](./meta-18_instance_settings-index.md#private-hub-base-url) to your Private Hub url.

:::warning
Authentication on the Hub is performed via the Windmill instance.
The Hub and Windmill instances must have the same root domain name for authentication to work.
For example, if the Windmill instance is available on windmill.example.com, the Hub must be accessible on a similar sub-domain such as hub.example.com.
You'll also need to set the COOKIE_DOMAIN [environment variable](./meta-47_environment_variables-index.md) of the Windmill instance (server) to the root domain name (e.g. example.com). 
If you're using the [Helm chart](https://github.com/windmill-labs/windmill-helm-charts/blob/main/charts/windmill/values.yaml#L50), there is a built-in `cookieDomain` value for this.
**Make sure to log out and log back in after setting the cookie domain.**
:::

If you are interested in having your own Private Hub, please [contact us](mailto:contact@windmill.dev).
