---
doc_id: meta/15_authentification/index
chunk_id: meta/15_authentification/index#chunk-5
heading_path: ["Authentication", "SCIM/SAML"]
chunk_type: prose
tokens: 92
summary: "SCIM/SAML"
---

## SCIM/SAML

Windmill supports [SCIM and SAML](../../misc/14_saml_and_scim/index.md) for user provisioning and authentication. When SCIM is configured, groups from your identity provider are automatically synchronized as [instance groups](./meta-8_groups_and_folders-index.md#instance-groups), eliminating the need for manual group management.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="SAML & SCIM"
		description="Configure Okta or Microsoft for both SAML and SCIM."
		href="/docs/misc/saml_and_scim"
	/>
	<DocCard
		title="Groups and folders"
		description="Learn about instance groups and how they work with SCIM."
		href="/docs/core_concepts/groups_and_folders#instance-groups"
	/>
</div>
