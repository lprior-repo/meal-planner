---
doc_id: meta/15_authentification/index
chunk_id: meta/15_authentification/index#chunk-3
heading_path: ["Authentication", "Manually Add Users to a Windmill Instance"]
chunk_type: prose
tokens: 256
summary: "Manually Add Users to a Windmill Instance"
---

## Manually Add Users to a Windmill Instance

As a superadmin of the instance, you have the ability to manually add users to the Windmill instance. This is useful for inviting users who do not have SSO credentials or for providing access to individuals outside the restricted domain.

To manually add users:

1. Log in to the Windmill instance as a superadmin.
2. Click on your username and pick [Instance settings](./meta-18_instance_settings-index.md).
3. Fill:
   - Email: The email address of the user.
   - Password: A password for the user's account.
   - Name (Optional): The name of the user.
   - Company (Optional): The company or organization the user belongs to.
4. "Add user to instance".

![Manually Add Users](./add_global_users.png 'Manually Add Users')

If [SMTP is configured](./meta-18_instance_settings-index.md#smtp), an email will be sent to the user with their account details and instructions for accessing Windmill.

By default, users are not invited to any workspace, unless auto-invite has been set-up.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/Wyq6d0bkuGo"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Self-host Windmill"
		description="Self host Windmill in 2 minutes."
		href="/docs/advanced/self_host#authentication-and-user-management"
	/>
</div>
