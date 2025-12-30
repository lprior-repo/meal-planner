---
doc_id: meta/18_instance_settings/index
chunk_id: meta/18_instance_settings/index#chunk-7
heading_path: ["Instance settings", "Alerts"]
chunk_type: code
tokens: 767
summary: "Alerts"
---

## Alerts

![Alerts](./alerts.png)

### Critical alert channels

Channels to send [critical alerts](./meta-37_critical_alerts-index.md) to. [SMTP](#smtp) must be configured for the email channel. A Slack workspace must be connected to the instance for the Slack channel. [Microsoft Teams](../../misc/2_setup_oauth/index.mdx#microsoft-teams) must be setup to configure critical alerts to be sent to a Microsoft Teams channel.

You can add multiple channels between Email, Slack, and Microsoft Teams.

![Critical alerts channels](./critical_alerts_channels.png 'Critical alerts channels')

Furthermore you can chose to mute [critical alerts in the UI](./meta-37_critical_alerts-index.md) using the "Mute critical alerts in UI" toggle.

This setting is only available on [Enterprise Edition](/pricing).

![Critical alert example](./teams_critical_alert.png 'Critical alert example')

### Mute critical alerts in UI

Enable to mute critical alerts in the UI.

### Slack

Connecting your instance to a Slack workspace enables [critical alerts](#critical-alert-channels) to be sent to a Slack channel.

Just click on the 'Connect to Slack' button and follow the instructions from Slack.

This setting is only available on [Enterprise Edition](/pricing).

### SMTP

Setting SMTP unlocks [sending emails upon adding new users](./meta-15_authentification-index.md) to the workspace or the instance and [sending critical alerts](#critical-alert-channels).

You need to provide the following details:

| Name   |  Type  | Description                                |
| ------ | ---- | -------------------------------------------- |
| Host   | String | SMTP server host                           |
| Port   | Number | SMTP server port                           |
| Username   | String | SMTP server user                       |
| Password   | String | SMTP server password                   |
| From Address  | String | Email address to send emails from   |
| Implicit TLS  | Boolean | Use implicit TLS (default: false)  |

You have another field to test the SMTP settings.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/Wyq6d0bkuGo"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br/>

<details>
  <summary>Set-up SMTP from the `.env` file (depreciated) </summary>

The relevant environment variables are:

```
SMTP_FROM=windmill@domain.com
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=email@domain.com
SMTP_PASSWORD=app_password
```

If you used the [Setup Windmill on localhost](./meta-1_self_host-index.md#setup-windmill-on-localhost) method, open the `.env` file in any text editor. You can use `nano`, `vim`, or any other editor you're comfortable with.

```bash
nano .env
```

Append the following to the end of your `.env` file:

```
SMTP_FROM=windmill@domain.com
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password
```

Make sure to replace `your_email@gmail.com` with your actual Gmail email address and `your_app_password` with the app password you've generated from Gmail.

{' '}

<br />

> **Note**: If you're using Gmail, you'll need to [generate an App Password](https://support.google.com/accounts/answer/185833?hl=en) to use as `SMTP_PASSWORD`. This is a unique password that Gmail provides for apps and services that want to connect to your account.

<br />

Save and Close the File:

- If using `nano`, press `CTRL + O` to save and then `CTRL + X` to exit.
- If using `vim`, press `Esc`, then type `:wq` and press `Enter`.

Restart your Windmill application:

- Since you've made changes to the `.env` file, you'll need to restart your Windmill application for the changes to take effect.

```bash
docker compose down
docker compose up -d
```

Now, your Windmill instance should use the SMTP settings you've provided to send invites and email to manually added users. Make sure the SMTP details you've provided are correct and that the Gmail account you're using has allowed less secure apps or generated an App Password.

</details>

### Set up auto-invites

When creating a workspace, you have the option to invite automatically everyone on the same domain. That's how you make sure that anyone added to the instance is also added to the workspace.

<video
	className="border-2 rounded-lg object-cover w-full h-full"
	controls
	id="new_workspace"
	src="/videos/new_workspace.mp4"
/>
