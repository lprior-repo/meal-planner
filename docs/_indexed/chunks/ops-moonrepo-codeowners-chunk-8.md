---
doc_id: ops/moonrepo/codeowners
chunk_id: ops/moonrepo/codeowners#chunk-8
heading_path: ["sync codeowners", "FAQ"]
chunk_type: prose
tokens: 265
summary: "FAQ"
---

## FAQ

### What providers or formats are supported?

The following providers are supported, based on the [`vcs.provider`](/docs/config/workspace#provider) setting.

- [Bitbucket](https://marketplace.atlassian.com/apps/1218598/code-owners-for-bitbucket?tab=overview&hosting=cloud) (via a 3rd-party app)
- [GitHub](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
- [GitLab](https://docs.gitlab.com/ee/user/project/codeowners/reference.html)
- Other (very basic syntax)

### Where does the `CODEOWNERS` file get created?

The location of the file is dependent on the configured provider.

- GitHub -> `.github/CODEOWNERS`
- GitLab -> `.gitlab/CODEOWNERS`
- Everything else -> `CODEOWNERS`

### Why are owners defined in `moon.yml` and not an alternative like `OWNERS`?

A very popular pattern for defining owners is through an `OWNERS` file, which can appear in any folder, at any depth, within the repository. All of these files are then aggregated into a single `CODEOWNERS` file.

While this is useful for viewing ownership of a folder at a glance, it incurs a massive performance hit as we'd have to constantly glob the *entire* repository to find all `OWNERS` files. We found it best to define owners in `moon.yml` instead for the following reasons:

- No performance hit, as we're already loading and parsing these config files.
- Co-locates owners with the rest of moon's configuration.
- Ownership is now a part of the project graph, enabling future features.

**Tags:**

- [code](/docs/tags/code)
- [owners](/docs/tags/owners)
- [codeowners](/docs/tags/codeowners)
