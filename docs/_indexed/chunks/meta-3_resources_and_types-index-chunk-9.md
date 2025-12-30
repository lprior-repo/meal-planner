---
doc_id: meta/3_resources_and_types/index
chunk_id: meta/3_resources_and_types/index#chunk-9
heading_path: ["Resources and resource types", "Plain text file resources"]
chunk_type: prose
tokens: 380
summary: "Plain text file resources"
---

## Plain text file resources

In certain scenarios it is useful to store data as a a text file, with a format such as `.json`, `.cfg`, etc. Windmill can store plain text files as a resource, which can then be used as arguments for scripts, or have special support in certain languages (e.g. [Ansible](./meta-10_ansible_quickstart-index.md)).

### Creating a plain text resource

You first need to create the resource type. You will find a toggle to indicate this file is a text file, turn it on. You can then enter the file extension that will define the file format. In this example we will choose `ini` and create a type to represent Ansible Inventories.

![Create a Text File Resource Type](./create_text_file_resource_type.png)

Under the hood, this resource type is just like others, but the schema only has a `content` field where the file contents are stored. Additionally, the format that you input will be used to diplay the contents on the frontend and also when pulling with the CLI and create a type to represent Ansible Inventories.

Now you can create the resource by adding a resource and searching your newly created resource type:

![Create a Text File Resource](./create_text_file_resource.png)

As you will notice, the format specified will be used for syntax highlighting when editing and displaying this file. When pulling this resource on the CLI, you will find two files: `<resource_name>.resource.file.ini` and `<resource_name>.resource.yaml`.

### Using the resource

This resource only has a `content` field, so any language can [use it](./meta-3_resources_and_types-index.md#using-resources) and access the `content` like for any other resource/object. In certain languages (currenttly only [Ansible](./meta-10_ansible_quickstart-index.md)), it can be preferable to have the file available on the file system instead of inlining its contents. You can ask Windmill to [create these files before the execution of the script](../getting_started/scripts_quickstart/ansible#other-non-inventory-file-resources).
