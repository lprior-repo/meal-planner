---
doc_id: meta/10_ansible_quickstart/index
chunk_id: meta/10_ansible_quickstart/index#chunk-3
heading_path: ["Ansible quickstart", "Code (Playbook)"]
chunk_type: prose
tokens: 85
summary: "Code (Playbook)"
---

## Code (Playbook)

In order to make Ansible playbooks compatible with the Windmill environment and script model, there is some extra information preceding the start of the playbook that can be entered. Because of this, an Ansible playbook in Windmill will typically look like this:

![Ansible in Windmill](./ansible_script_ide.png)

```yml
---
inventory:
  - resource_type: ansible_inventory
    # You can pin an inventory to this script:
    # resource: u/user/your_resource
