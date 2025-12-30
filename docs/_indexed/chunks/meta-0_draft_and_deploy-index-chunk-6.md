---
doc_id: meta/0_draft_and_deploy/index
chunk_id: meta/0_draft_and_deploy/index#chunk-6
heading_path: ["Draft and deploy", "Special case: Deployed versions of scripts"]
chunk_type: prose
tokens: 154
summary: "Special case: Deployed versions of scripts"
---

## Special case: Deployed versions of scripts

Apps and Flows only have one deployed version at a given path and doing a new deployment overwrite the previous one.

Scripts are special because each deployment of a script creates an immutable hash that will never be overwritten. The path of a script serves as a redirection to the last deployed hash, but all hashes live permanently forever. This ensures that if you refer to a script by its hash, its behavior is guaranteed to remain the same even if a new hash is deployed at the same path.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Versioning"
		description="Scripts, when deployed, can have a parent script identified by its hash."
		href="/docs/core_concepts/versioning#script-versioning"
	/>
</div>
