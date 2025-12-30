---
doc_id: meta/15_authentification/index
chunk_id: meta/15_authentification/index#chunk-2
heading_path: ["Authentication", "Restricted domain authentication"]
chunk_type: prose
tokens: 163
summary: "Restricted domain authentication"
---

## Restricted domain authentication

Windmill supports authentication [through SSO](../../misc/2_setup_oauth/index.mdx) for users with email addresses from a restricted domain. This allows organizations to control access to Windmill based on their domain policy. Users with email addresses from the authorized domain can authenticate seamlessly using their SSO credentials.

To enable restricted domain authentication, an administrator can configure the authorized domain in the OAuth configuration by setting 'allowed_domains' to the desired domains (e.g: 'windmill.dev' to accept only Google/Microsoft logins with a xxx@windmill.dev address). Once configured, users with email addresses from the authorized domain will be able to log in using their SSO provider.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Setup OAuth and SSO"
		description="Windmill supports Single Sign-On for Microsoft, Google, GitHub, GitLab, Okta, and domain restriction."
		href="/docs/misc/setup_oauth"
	/>
</div>
