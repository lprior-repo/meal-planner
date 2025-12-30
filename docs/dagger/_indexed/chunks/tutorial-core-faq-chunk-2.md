---
doc_id: tutorial/core/faq
chunk_id: tutorial/core/faq#chunk-2
heading_path: ["faq", "General"]
chunk_type: prose
tokens: 764
summary: "We're building the devops operating system, an integrated platform to orchestrate the delivery of..."
---
### What is the Dagger Platform?

We're building the devops operating system, an integrated platform to orchestrate the delivery of applications to the cloud from start to finish. The Dagger Platform includes the Dagger Engine, Dagger Cloud, and the Dagger SDKs.

### How do I install, update, or uninstall Dagger?

Refer to the [installation documentation](./ops-getting-started-installation.md).

### Does Dagger send telemetry?

By default, the Dagger CLI sends anonymized telemetry to dagger.io. This allows us to improve Dagger by understanding how it is used. Telemetry is optional and can be disabled at any time. If you are willing and able to leave telemetry enabled: thank you! This will help us better understand how Dagger is used, and will allow us to improve your experience.

### What telemetry does Dagger send?

The following information is included in telemetry:

- Dagger version
- Platform information
- Command run
- Anonymous device ID

We use telemetry for aggregate analysis, and do not tie telemetry events to a specific identity. Our telemetry implementation is open-source and can be reviewed in our [GitHub repository](https://github.com/dagger/dagger).

### Can Dagger telemetry be disabled?

Dagger implements the [Console Do Not Track (DNT) standard](https://consoledonottrack.com/). As a result, you can disable the telemetry by setting the environment variable `DO_NOT_TRACK=1` before running the Dagger CLI.

### Can I configure the Dagger Engine?

Yes. [Read more about Dagger Engine configuration](https://github.com/dagger/dagger/blob/main/core/docs/d7yxc-operator_manual.md).

### Can I use Dagger Engine to build Windows Containers?

Unfortunately, not right now. Dagger runs on top of BuildKit and support for Windows Containers is still experimental in BuildKit. In addition, Dagger has a lot of custom code written on top of BuildKit such as networking, init systems, and Linux namespace entries, that do not have exact parallels on Windows.

### Why does the Dagger Engine need to run in a privileged container?

Currently, the Dagger Engine must run in a privileged container, because network and filesystem constraints related to rootless usage would currently significantly limit its capabilities and performance.

#### Filesystem constraints

The Dagger Engine relies on the `overlayfs` snapshotter for efficient construction of container filesystems. However, only relatively recent Linux kernel versions fully support `overlayfs` inside of rootless user namespaces. On older kernels, there are fallback options such as [`fuse-overlayfs`](https://github.com/containers/fuse-overlayfs), but they come with their own complications in terms of degraded performance and host-specific setup.

We've not yet invested in the significant work it would take to support+document running optimally on each kernel version, hence the limitation at this time.

#### Network constraints

Running the Dagger Engine in an unprivileged container constrains network management due to the fact that it's not possible for such a container to move a network device from the host network namespace to its own network namespace.

It is possible to use userspace TCP/IP implementations such as [slirp](https://github.com/rootless-containers/slirp4netns) as a workaround, but they often significantly decrease network performance. This [comparison table of network drivers](https://github.com/rootless-containers/rootlesskit/blob/master/docs/network.md#network-drivers) shows that `slirp` is at least five times slower than a root-privileged network driver.

Newer options for more performant userspace network stacks have arisen in recent years, but they are generally either reliant on relatively recent kernel versions or in a nascent stage that would require significant validation around robustness+security.

From a security standpoint, approach securing Dagger as you would approach securing Docker or Kubernetes. Usually, that means treating it like a host service and making the host machine the security boundary.

### I am stuck. How can I get help?

Join us on [Discord](https://discord.com/invite/dagger-io), and ask your question in our [help forum](https://discord.com/channels/707636530424053791/1030538312508776540). Our team will be happy to help you there!
