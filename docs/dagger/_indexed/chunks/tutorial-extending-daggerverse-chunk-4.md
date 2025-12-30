---
doc_id: tutorial/extending/daggerverse
chunk_id: tutorial/extending/daggerverse#chunk-4
heading_path: ["daggerverse", "Publishing"]
chunk_type: prose
tokens: 593
summary: "Two processes are available to publish your Dagger module to the Daggerverse, manual and automati..."
---
Two processes are available to publish your Dagger module to the Daggerverse, manual and automatic on use.

### Manual publishing

To manually publish a module to the Daggerverse, follow the steps below:

1. To publish a Dagger module to the Daggerverse, the module must be pushed to a public git repository. Dagger is agnostic to repository layout, and any number of Dagger modules can peacefully coexist in a repository. It's up to you how to organize your module's source code in Git. Some like to publish each module as a dedicated repository; others like to organize all their modules together, with the git repository acting as a "catalog". These repositories are often named "daggerverse" by convention.

2. Navigate to the [Daggerverse](https://daggerverse.dev) and click the `Publish` button. On the resulting page, paste the URL to the Git repository containing your module in the format `GITSERVER/USERNAME/REPOSITORY[/SUBPATH][@VERSION]`. For example, `github.com/shykes/hello@v0.3.0` or `github.com/shykes/daggerverse/termcast@main`

3. Click "Publish" to have your Dagger module published to the Daggerverse. This process may take a few minutes. Once complete, your Dagger module will appear in the Daggerverse module listing.

> **Important:**
> - Most Git servers should "just work", but please let us know if you encounter any issues.
> - The Daggerverse only fetches publicly available information from Git servers. Modules are not hosted on the Daggerverse. If you need a module removed from the Daggerverse for some reason, let the Dagger team know in [Discord](https://discord.gg/dagger-io).

### Publishing on use

Every time that a user executes `dagger ...`, if any of the Dagger Functions which are invoked in the execution come from a remote Dagger module (here, a remote module is defined as a module whose location is specified by a URL like `GITSERVER/USERNAME/daggerverse/...`), that Dagger module will automatically be published to the Daggerverse.

> **Note:** Under this process, it is possible for some Dagger modules to appear in the Daggerverse even when they're not fully ready. An example of this is when the module developer is developing the module in a local development environment and pushing work-in-progress to the Git repository. In this case, as soon as the module developer tags the module with a [valid semantic version number](#semantic-versioning), the module will be considered released and the latest version will be published to the Daggerverse.

### Semantic versioning

Dagger modules should be versioned according to [semantic versioning principles](https://semver.org/). This means that the published module reference should be tagged with a pattern matching `vMAJOR.MINOR.PATCH`, such as `v1.2.3`.

> **Important:** At this time, only version numbers matching the `vMAJOR.MINOR.PATCH` versioning pattern are considered valid.

In monorepos of modules, modules can be independently versioned by prefixing the tag with the subpath. For example a module named `foo` can be tagged with `foo/v1.2.3` and referenced as `GITSERVER/USERNAME/REPOSITORY/foo@v1.2.3`.
