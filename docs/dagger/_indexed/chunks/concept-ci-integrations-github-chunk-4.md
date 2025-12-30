---
doc_id: concept/ci-integrations/github
chunk_id: concept/ci-integrations/github#chunk-4
heading_path: ["github", "Examples"]
chunk_type: mixed
tokens: 118
summary: "Given a Dagger Function called `foo` that accepts a `Directory` as argument, you can pass it a Gi..."
---
Given a Dagger Function called `foo` that accepts a `Directory` as argument, you can pass it a GitHub pull request URL as argument like this:

```
dagger call foo --directory=https://github.com/ORGANIZATION/REPOSITORY#pull/NUMBER/merge
```

If your GitHub repository contains a Dagger module, you can test the functionality of a specific branch by calling the Dagger module with the corresponding pull request URL, as shown below:

```
dagger call -m github.com/ORGANIZATION/REPOSITORY@pull/NUMBER/merge --help
```

You can also use a Dagger Function in a GitHub Actions workflow to publish a container image to GitHub Container Registry.

```yaml
