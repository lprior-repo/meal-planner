---
doc_id: tutorial/extending/remote-repositories
chunk_id: tutorial/extending/remote-repositories#chunk-3
heading_path: ["remote-repositories", "Authentication methods"]
chunk_type: prose
tokens: 325
summary: "Dagger supports both HTTPS and SSH authentication for accessing remote repositories."
---
Dagger supports both HTTPS and SSH authentication for accessing remote repositories.

### HTTPS authentication

For HTTPS authentication, Dagger uses your system's configured Git credential manager. This means if you're already authenticated with your Git provider, Dagger will automatically use these credentials when needed.

The following credential helpers are supported:

- [Git Credential Manager](https://github.com/git-ecosystem/git-credential-manager)
- macOS Keychain
- Windows Credential Manager
- Custom credential helpers configured in your `.gitconfig`

To verify if your credentials are properly configured, try cloning a private repository (replace the placeholders below with valid values):

```bash
git clone https://github.com/USER/PRIVATE_REPOSITORY.git
```

If this works, Dagger will be able to use the same credentials to access your private repositories.

#### Credential manager configuration

- **GitHub**: Use [`gh auth login`](https://docs.github.com/en/get-started/getting-started-with-git/caching-your-github-credentials-in-git#github-cli) or [configure credentials via Git Credential Manager](https://docs.github.com/en/get-started/getting-started-with-git/caching-your-github-credentials-in-git#git-credential-manager)
- **GitLab**: Use [`glab auth login`](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/auth/login.md) or [configure credentials via Git Credential Manager](https://github.com/git-ecosystem/git-credential-manager)
- **Azure DevOps**: Use [Git Credential Manager](https://learn.microsoft.com/en-us/azure/devops/repos/git/set-up-credential-managers)
- **BitBucket**: Configure credentials using the [Git credential system](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage) (the widely-adopted implementation is [Git Credential Manager](https://github.com/git-ecosystem/git-credential-manager))

### SSH authentication

Dagger mounts the socket specified by your host's `SSH_AUTH_SOCK` environment variable to the Dagger Engine. This is essential for SSH refs, as most Git servers use your SSH key for authentication and tracking purposes, even when cloning public repositories.

This means that you must ensure that the `SSH_AUTH_SOCK` environment variable is properly set in your environment when using SSH refs with Dagger.

[Read detailed instructions on setting up SSH authentication](https://docs.github.com/en/authentication/connecting-to-github-with-ssh), including how to generate SSH keys, start the SSH agent, and add your keys.
