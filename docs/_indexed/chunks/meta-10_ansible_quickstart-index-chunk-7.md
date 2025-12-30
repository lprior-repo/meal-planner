---
doc_id: meta/10_ansible_quickstart/index
chunk_id: meta/10_ansible_quickstart/index#chunk-7
heading_path: ["Ansible quickstart", "Define the arguments of the Windmill script"]
chunk_type: code
tokens: 1046
summary: "Define the arguments of the Windmill script"
---

## Define the arguments of the Windmill script
extra_vars:
  world_qualifier:
    type: string

dependencies:
  galaxy:
    collections:
      - name: community.general
      - name: community.vmware
  python:
    - jmespath
---
- name: Echo
  hosts: 127.0.0.1
  connection: local
  vars:
    my_result:
      a: 2
      b: true
      c: "Hello"

  tasks:
  - name: Print debug message
    debug:
      msg: "Hello, {{world_qualifier}} world!"
  - name: Write variable my_result to result.json
    delegate_to: localhost
    copy:
      content: "{{ my_result | to_json }}"
      dest: result.json
```

There are two YAML documents in series, the second being the Ansible playbook. The first one is only used by Windmill, and will not be visible to Ansible when executing the playbook. It contains different sections that declare some metadata about the script.

We will now go thorugh each of these sections.

### Arguments (extra-args)

Windmill scripts can take [arguments](./meta-13_json_schema_and_parsing-index.md), and in order to define the names and types of the arguments you can use this section. These definitions will be parsed allowing the frontend to interactively display dynamic inputs for the script.


```yaml
extra_vars:
  world_qualifier:
    type: string
  nested_object:
    type: object
    properties:
      a:
        type: string
      b:
        type: number
  some_arr:
    type: array
    objects:
      type: string
```

![Parsing Yaml and generating UI](./extra_vars_ui.png)

The type definition is inspired and tries to follow the [OpenAPI Data Types standard](https://swagger.io/docs/specification/data-models/data-types/). Note that not all features / types are supported, the best way to know what is supported is to test it out in the Web IDE.

:::tip Argument defaults
You can set a default value for your arguments by using a `default:` field, for example:
```yml
extra_vars:
  my_string:
    type: string
    default: 'Fascinating String of Words'
```
:::

To use Windmill [resources](./meta-3_resources_and_types-index.md) as types you can use the following type definition:

```yaml
extra_vars:
  my_resource:
    type: windmill_resource
    resource_type: postgresql
```

![Postgres Resource UI](./postgres_ui.png)

Under the hood, Windmill will pass these variables using the `--extra-vars` flag to Ansible, so you can expect the according behavior.

### Static resources and variables

Resources and [variables](./meta-2_variables_and_secrets-index.md) that are hardcoded to a particular script can also be defined in the `extra-vars` section. This is because they are similarly passed through the `--extra-vars` flag in the Ansible playbook.

This is what the syntax looks like:
```yml
extra_vars:
  my_variable:
    type: windmill_variable
    variable: u/user/my_variable
  my_resource:
    type: windmill_resource
    resource: u/user/my_resource
```

Under `resource` or `variable` you can statically link the path to the resource/variable. As you do, you will notice the UI update and hide the resource input as it is now static.

:::tip About static and non-static variables
Note that Variables defined this way can only be static. If you want to use non-static Variables, define a normal argument with `type: string` and from the UI fill it with one of your Variables or Secrets.
:::

### Return values

In Windmill scripts usually have a return value, which allows scripts to be chained in flows and run conditionally on the result of a previous operation. For Ansible playbooks you can achieve the same result by having one of the tasks (preferably the last one for coherence of results/errors) write a file named `result.json` with the JSON object you want to return:

```yaml
---
tasks:

  [...]

  - name: Write variable my_result to result.json
    delegate_to: localhost
    copy:
      content: "{{ my_result | to_json }}"
      dest: result.json

```

Note that valid json must be written to the file or else the job will fail. Also, this should be done by the control node i.e. your worker, so it's important to use the `delegate_to: localhost` directive.


### Inventories

When using ansbile playbooks, you would usually run a command such as `ansible-playbook playbook.yml -i inventory.ini`. The ways to pass inventories to Ansible in Windmill is by filling the following section:

```yaml
inventory:
  - resource_type: ansible_inventory
```

To create similar resource type, refer to [creating plain text resources](./meta-3_resources_and_types-index.md#plain-text-file-resources). Otherwise `ansible_inventory` should be available after syncing resource types from the hub.

After adding this in the Web IDE, you will see a new `inventory.ini` argument pop up. You can then select or create a new ansible_inventory resource.

![inventory ui](./inventory_ui.png)

If you don't want one of the inputs of the script be the inventory, you can pin a specific resource to the script by specifying its path. In this case you don't need to specify the resource_type anymore:

```yaml
inventory:
  - resource: u/user/my_ansible_inventory
```

Then the UI will not prompt you for the inventory but will use this resource at every run of the script. If otherwise you wish to not specify any inventory, you can remove the section altogether

By default, the inventory will be named `inventory.ini`, but if your inventory needs to have a different extension (e.g. dynamic invetories) you can specify the name of the inventory file like this:

```yaml
inventory:
  - resource_type: c_dynamic_ansible_inventory
    name: hcloud.yml
```

Additionally, if you need to pass multiple inventories, you just need to continue the yaml array with your other invetories, they will all be passed to the `ansible-playbook` command.

```yaml
