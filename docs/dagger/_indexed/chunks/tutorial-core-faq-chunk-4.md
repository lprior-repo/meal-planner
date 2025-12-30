---
doc_id: tutorial/core/faq
chunk_id: tutorial/core/faq#chunk-4
heading_path: ["faq", "Dagger SDKs"]
chunk_type: prose
tokens: 377
summary: "We have [three types of SDKs](https://dagger."
---
### What language SDKs are available for Dagger?

We have [three types of SDKs](https://dagger.io/community-sdks), with varying levels of parity and support: official, community and experimental. We currently offer official SDKs for Go, TypeScript and Python. A community SDK is available for PHP, and an experimental SDK is available for Java.

### How can I move my SDK to a Dagger Community SDK?

To ensure a great experience for developers using Community SDKs, maintainers must meet the following requirements if you would like your SDK to graduate to the Community SDK level:

- Community Support – The maintainer must be active in the Dagger Discord, providing support and answering questions about the SDK.
- Version Compatibility – The SDK must stay up to date with the latest Dagger releases to ensure continued functionality.
- Documentation Maintenance – The maintainer is responsible for writing and updating documentation, including code snippets and examples. See full list of documentation requirements [here](https://docs.google.com/spreadsheets/d/1pvpzZbWarkuws811NEEbnv2D-ggec4iuZeYhUyVwsWc/edit?gid=245490315#gid=245490315).
- Openness to Contributions – Community SDKs should be open-source and encourage contributions from other developers.

If you want to kick off this process for your SDK, email [community@dagger.io](mailto:community@dagger.io) and we'll discuss further.

### How do I log in to a container registry using a Dagger SDK?

There are two options available:

1. Use the [`Container.withRegistryAuth()`](https://docs.dagger.io/api/reference/#Container-withRegistryAuth) GraphQL API method. A native equivalent of this method is available in each Dagger SDK.
2. Dagger SDKs can use your existing Docker credentials without requiring separate authentication. Simply execute `docker login` against your container registry on the host where your Dagger workflows are running.

### How do I uninstall a Dagger SDK?

To uninstall a Dagger SDK, follow the same procedure that you would follow to uninstall any other SDK package in your chosen development environment.
