---
doc_id: tutorial/core/faq
chunk_id: tutorial/core/faq#chunk-3
heading_path: ["faq", "Dagger Cloud"]
chunk_type: prose
tokens: 663
summary: "Dagger Cloud complements the Dagger Engine with a production-grade control plane."
---
### What is Dagger Cloud?

Dagger Cloud complements the Dagger Engine with a production-grade control plane. Features of Dagger Cloud include workflow visualization and operational insights.

### Is Dagger Cloud a hosting service for Dagger Engines?

No, Dagger Cloud is a "bring your own compute" service. The Dagger Engine can run on a wide variety of machines, including most development and CI platforms. If the Dagger Engine can run on it, then Dagger Cloud supports it.

### Which CI providers does Dagger Cloud work with?

Because the Dagger Engine can integrate seamlessly with practically any CI, there is no limit to the type and number of CI providers that Dagger Cloud can work with to provide Dagger workflow visualization and operational insights. Users report successfully leveraging Dagger with: GitLab, CircleCI, GitHub Actions, Jenkins, Tekton and many more.

### What is workflow visualization?

Traces, a browser-based interface focused on tracing and debugging Dagger workflow runs. A Trace contains detailed information about the steps performed by the workflow. Traces let you visualize each step of your workflow, drill down to detailed logs, understand how long operations took to run, and whether operations were cached.

### What operational insights does Dagger Cloud provide?

Dagger Cloud collects telemetry from all your organization's Dagger Engines, whether they run in development or CI, and presents it all to you in one place. This gives you a unique view on all workflows, both pre-push and post-push.

### Why am I seeing `dagger functions` in the local trace list?

All commands that require module initialization at an engine level will send telemetry to Dagger Cloud. Dagger needs to introspect a module to be able to print the available functions in a module, so it calls `dagger functions`. This happens for both local and remote runs, which is why the calls appears in the local trace list.

### How does Dagger classify Traces as originating from "CI" or "local"?

Dagger is aware of the context it runs on. When it runs in a CI context like GitHub, GitLab, CircleCI, or Jenkins, additional Trace metadata is displayed based on the Git repository information available. For this reason, it is important for Dagger to run in a Git context when running in CI.

### What are "orphaned Traces"?

You might see a warning message in Dagger Cloud about orphaned Traces. Orphaned Traces are Traces emitted in a CI context, that contain incomplete or no Git metadata. This generally happens when Git is not properly set up in the CI context that Dagger runs in. In GitHub Actions, for example, this context can be provided by using the `checkout` action in the step where Dagger is called.

### My CI provider is not supported in Dagger Cloud. Is there a way I can "force" my Traces into the Dagger Cloud dashboard?

It's possible to send Traces by setting the `CI=true` variable in Dagger's runtime environment. However, Traces with incomplete Git repository data will show up as orphaned, so it is important to ensure that Dagger is running in a properly-set Git context.
