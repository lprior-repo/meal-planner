---
doc_id: meta/17_email_triggers/index
chunk_id: meta/17_email_triggers/index#chunk-2
heading_path: ["Email triggers", "Configuration"]
chunk_type: prose
tokens: 293
summary: "Configuration"
---

## Configuration

Email triggers is available on both [cloud](#cloud) and [self-hosted](#self-hosted) instances.

### Cloud

On [cloud](https://app.windmill.dev/) instances, Email triggers is already configured. You can try it from `demo` workspace.

![Email triggers from cloud](./email_triggers_cloud.png "Email triggers from cloud")

### Self-hosted

First, make sure that the port 25 is exposed either on your instance public IP or a separate IP and that it redirects to the Windmill app on port 2525.
The Caddyfile already contains the necessary configuration for this.
For Kubernetes, you will find example configurations for some providers on the [Windmill helm charts repository](https://github.com/windmill-labs/windmill-helm-charts).

In addition, you will need to create one or two records in your DNS provider depending on your setup.

If the port 25 is exposed on the same IP as the Windmill instance (e.g. [docker-compose](https://github.com/windmill-labs/windmill/blob/main/docker-compose.yml) with Caddy):
  - An MX record from `mail.<instance domain>` to `<instance domain>`.

If the port 25 is exposed through a different IP (e.g. Kubernetes):
  - An A/CNAME record that points to the IP of the Windmill instance with port 25 exposed (for example `mail_server.<instance domain>`).
  - An MX record from `mail.<instance domain>` to the record defined above (`mail_server.<instance domain>` if following the example).

You can choose any email domain, we suggest using `mail.<instance domain>`.
Once you have defined the DNS settings, set the email domain in the [instance settings](./meta-18_instance_settings-index.md#email-domain) under the "Core" tab.

![Instance settings](./instance_settings.png "Instance settings")
