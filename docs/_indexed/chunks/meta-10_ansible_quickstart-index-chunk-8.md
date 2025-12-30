---
doc_id: meta/10_ansible_quickstart/index
chunk_id: meta/10_ansible_quickstart/index#chunk-8
heading_path: ["Ansible quickstart", "Declaring three different inventories to be passed to the playbook"]
chunk_type: code
tokens: 912
summary: "Declaring three different inventories to be passed to the playbook"
---

## Declaring three different inventories to be passed to the playbook
inventory:
  - resource: u/user/my_base_inventory
    name: base.ini
  - resource_type: ansible_inventory
  - resource_type: c_dynamic_ansible_inventory
    name: hcloud.yml
```

### Additional inventories

You can also declare additional inventories that will be made available as script arguments without specifying their source. This allows users to dynamically select inventories when running the script.

```yaml
additional_inventories:
  - name: "Extra inventories"
    options:
      - "delegate_git_repository/hosts/inventory1.ini"
      - "delegate_git_repository/hosts/inventory2.ini"
      - "delegate_git_repository/hosts/inventory3.ini"
```

They can also be defined statically to always be passed in for this script:

```yaml
additional_inventories:
  - "delegate_git_repository/hosts/permanent_inventory.ini"
```

Note that this only declares the inventory, but you still need to make it available by either having it in a git repo or using [file resources](#other-non-inventory-file-resources). Otherwise ansible will fail saying it couldn't find your inventory.

### Other non-inventory file resources

It sometimes happens that your Ansible playbook depends on some text file existing at a relative path to the playbook. This can be a configuration file, a template, some other file that you can't inline or otherwise is simpler to keep as a separate file. In this case, Windmill's [plain text file resources](./meta-3_resources_and_types-index.md#plain-text-file-resources) can be used to create these files at the specified path before running the playbook. The syntax will be the following:

```yaml
files:
  - resource: u/user/fabulous_jinja_template
    target:  ./config_template.j2
```

In the example above, the resource `u/user/faboulous_jinja_template` is a special plain text file resource. The target `./config_template.j2` is the path relative to the playbook where the file will be created and where the playbook can access it.

Now you can write your playbook assuming that this file will exist at the time of execution.

#### Variable inside files

If you want to achieve a similar effect with a variable or a secret, you can use a similar syntax:

```yaml
files:
  - variable: u/user/my_ssh_key
    target:  ./id_rsa
```

And the content of the variable will be written to the file.

This is useful when you want to store the data in a secret for example, like you would do for SSH keys.

#### Ansible and SSH

To succesfully have the playbook SSH, you might need to follow these tips:

1) Write the SSH key into a *secret* variable, and **make sure it has an ending newline**, otherwise you might get an error.

```
-----BEGIN OPENSSH PRIVATE KEY-----
MHgCAQEEIQDWlK/Rk2h4WGKCxRs2SwplFVTSyqouwTQKIXrJ/L2clqAKBggqhkjO
PQMBB6FEA0IABErMvG2Fa1jjG7DjEQuwRGCEDnVQc1G0ibU/HI1BjkIyf4d+sh
91GhwKDvHGbPaEQFWeTBQ+KbYwjtomLfmZM[...]
-----END OPENSSH PRIVATE KEY-----

```

2) Make a file for the script that will contain this SSH key. Make sure to add the `mode: '0600'` or you might get another error.

```yaml
files:
  - variable: u/user/my_ssh_key
    target:  ./ssh_key
    mode: '0600'
```

3) In your inventory file, you'll want to add these :
```ini
...
[your_host:vars]
ansible_host=your_host
ansible_user=john # The SSH user
ansible_ssh_private_key_file=ssh_key # The file we declared where the SSH key can be found.
ansible_ssh_common_args='-o StrictHostKeyChecking=no' # This skips host key verification, avoiding the error. Alternatively, you can add the host to known_hosts, either as an init script or a task in your playbook
...
```

### Dependencies

Ansible playbooks often depend on Python packages or Ansible Galaxy Collections. In Windmill you can specify these dependencies in the `dependencies` section and Windmill will take care of satisfying them before running the playbook.

```yaml
dependencies:
  galaxy:
    collections:
      - name: community.general
      - name: community.vmware
    roles:
      - name: geerlingguy.apache
  python:
    - jmespath
```

The syntax is similar to `ansible-builder` and Execution Environments, however all is installed locally using the same technology as for managing [Python dependencies](./meta-15_dependencies_in_python-index.md) in Python scripts, meaning no extra container is created.

:::info Ansible vs Ansible-core
Currently the Windmill image supporting Ansible runs the full `ansible` and not `ansible-core`. You can expect the respective collections to be preinstalled.
:::

### Git repo dependencies

Outside of galaxy dependencies, a role or collection can exist on a git repo and be imported as such. The only caveat is that the repo needs to be a valid role or collection at its root. Check the [ansible documentation](https://docs.ansible.com/ansible/latest/collections_guide/collections_installing.html#install-multiple-collections-with-a-requirements-file) for more information.

```yaml
collections:
  - name: git+https://github.com/organization/collection.git
    type: git
    version: main
```

To enable more flexibility however, it is possible to declare a git repo to be cloned at a specified location before the playbook is run. You can do this as follows:

```yaml
git_repos:
  - url: git@github.com:some_user/your_git_repo.git
    target: ./git_repo1
    commit: a34ac4fa
    branch: prod
