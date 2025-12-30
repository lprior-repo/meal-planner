---
doc_id: meta/8_groups_and_folders/index
chunk_id: meta/8_groups_and_folders/index#chunk-5
heading_path: ["Groups and folders", "Instance groups"]
chunk_type: prose
tokens: 386
summary: "Instance groups"
---

## Instance groups

Instance groups are a special type of group that are automatically managed and synced from your identity provider through [SCIM](../../misc/14_saml_and_scim/index.md#scim) (System for Cross-domain Identity Management). These groups provide enterprise-level user and group management without requiring manual provisioning within Windmill.

### Key characteristics

**Automatic synchronization**: Instance groups are automatically created, updated, and removed based on your identity provider's group structure. This eliminates the need for manual group management in Windmill.

**Enterprise integration**: They seamlessly integrate with enterprise identity providers like Okta, Microsoft Azure Active Directory, and other SCIM-compatible systems.

**Instance-wide scope**: Unlike regular workspace groups, instance groups operate at the instance level and can be used across multiple workspaces within your Windmill instance.

**Hands-off management**: Once SCIM is configured, your IT administrators can manage group membership directly in your identity provider, and changes will automatically reflect in Windmill.

### How instance groups work

1. **SCIM configuration**: Your Windmill instance is configured to accept SCIM provisioning from your identity provider
2. **Group synchronization**: Groups from your identity provider are automatically synced to Windmill as instance groups
3. **User assignment**: When users are added to groups in your identity provider, they automatically gain the corresponding group membership in Windmill
4. **Permission inheritance**: Instance groups can be assigned to folders and resources just like regular groups, inheriting the same permission levels (Viewer, Writer, Admin)

### Benefits

- **Reduced administrative overhead**: No need to manually create and manage groups in Windmill
- **Consistency**: Groups remain synchronized with your organization's identity structure
- **Security**: Centralized group management through your existing identity provider
- **Scalability**: Easily manage large numbers of users and groups across your organization

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="SAML & SCIM"
		description="Configure Okta or Microsoft for both SAML and SCIM to enable instance groups."
		href="/docs/misc/saml_and_scim"
	/>
</div>
