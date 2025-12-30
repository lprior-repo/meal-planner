---
doc_id: meta/10_ansible_quickstart/index
chunk_id: meta/10_ansible_quickstart/index#chunk-9
heading_path: ["Ansible quickstart", "An https or ssh url can be used:"]
chunk_type: code
tokens: 661
summary: "An https or ssh url can be used:"
---

## An https or ssh url can be used:
  - url: https://github.com/some_user/your_other_git_repo.git
    target: ./git_repo2
```

:::info Specifying a commit for your repo
If you do not specify the commit to be used, the latest commit hash will be stored in the script lockfile on deployment, and all subsequent executions will use that commit. This is done to ensure reproducibility. If you need to update this, you can simply redeploy the script
:::

If you want to clone a private repo, you can add the ssh private key like so:
```yaml
git_ssh_identity:
  - u/user/ssh_id_priv
git_repos:
  - url: git@github.com:some_user/your_private_repo.git
    target: ./my_roles_and_collections
```

### Ansible Vault

If you have files that are encripted by ansible vault, you need to pass a password to decrypt them. This can be easily done by storing the password as a Windmill secret, and specifying the path to the secret in the metadata section of your playbook:

```yaml
vault_password: u/user/ansible_vault_password
```

If you are using multiple vault password with Vault IDs, the setup is slightly different. You need to define your password files, and also add them as [file resources](#other-non-inventory-file-resources):

```yaml
vault_id:
  - label1@password_filename1
  - label2@password_filename2
  - label3@password_filename3
files:
  - variable: u/user/password_for_label1
    target: ./password_filename1
  - variable: u/user/password_for_label2
    target: ./password_filename2
  - variable: u/user/password_for_label3
    target: ./password_filename3
```

### Delegate the environment setup to a git repo (EE)

:::info EE feature
Parts of this feature depend on instance-wide blob storage, which is only available in Enterprise Edition.
:::


<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	controls
	src="/videos/ansible_delegate_to_git_repo.mp4"
/>

You can choose to set a git repository that contains all your inventories, custom roles, and playbooks as an alternate way to run your ansible script. When declaring this you will get an additional UI that lets you explore the repository, and some helpers to help you define the inventories.
You can do this by either declaring this section on the metadata part of the script:

```yaml
delegate_to_git_repo:
  resource: u/user/git_repo_resource
```

Or using the utility button that will help you pick a git repo resource to be used.

You will need to first create a git_repository resource that points to the repository you're trying to use.

You will then see your editor split in two and a Hovering popup indicating the alternate execution mode is detected. The first time you do this the repo viewer will show a button to load the git repository. This will clone and cache the contents of your repository in blob storage, for you to explore the files from within windmill.

If you click on the top-right floating pop-up, you will access a screen letting you manage the definition of the git repo, and will contain some utils for ease of use. You can for example use the inventories section to define a subfolder containing your inventories and quickly import the filenames into the script.

If you want to set a path to the playbook you want executed, you can do so like so:

```yaml
delegate_to_git_repo:
  resource: u/user/git_repo_resource
  playbook: playbooks/your_playbook.yml
```

If this is undefined, the worker will default to using the second YAML section like normal.
