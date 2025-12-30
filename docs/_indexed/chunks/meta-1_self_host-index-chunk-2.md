---
doc_id: meta/1_self_host/index
chunk_id: meta/1_self_host/index#chunk-2
heading_path: ["Self-host", "Cloud provider-specific guides"]
chunk_type: prose
tokens: 566
summary: "Cloud provider-specific guides"
---

## Cloud provider-specific guides

For instances with specific cloud providers requirements:

- [AWS, GCP, Azure](#aws-gcp-azure-neon)
- [Ubicloud](#ubicloud)
- [Fly.io](#flyio)
- [Hetzner, Fargate, Digital Ocean, Linode, Scaleway, Vultr, OVH, ...](#hetzner-fargate-digital-ocean-linode-scaleway-vultr-ovh-)

If you have no specific requirements, see [Docker](#docker).

### AWS, GCP, Azure, Neon

We recommend using the [Helm chart](#helm-chart) to deploy on managed [Kubernetes](https://kubernetes.io/). But for simplified setup, simply use the docker-compose (see [below](#docker)) on a single large instance and use a high number of replicas for the worker service.

The rule of thumb is 1 worker per 1vCPU and 1-2 GB of RAM. Cloud providers have managed load balancer services (ELB, GCLB, ALB) and managed database (RDS, Cloud SQL, Aurora, Postgres on Azure). We recommend disabling the db service in docker-compose and using an external database by setting the `DATABASE_URL` in the [.env][windmill-env] file for handling [environment variables](./meta-47_environment_variables-index.md).

Windmill is compatible with [AWS Aurora](https://aws.amazon.com/rds/aurora/), [GCP Cloud SQL](https://cloud.google.com/sql), [Azure](https://azure.microsoft.com/en-us) and [Neon](https://neon.tech/) serverless database.

Use the managed load balancer to point to your instance on the port you have chosen to expose in the caddy section of the docker-compose (by default 80). We recommend doing TLS termination and associating your domain on your managed load balancer. Once the domain name is chosen, set BASE_URL accordingly in `.env`. That is it for a minimal setup. Read about [Worker groups](./meta-9_worker_groups-index.md) to configure more finely your workers on more nodes and with different resources. Once done, be sure to setup [SSO login](../../misc/2_setup_oauth/index.mdx) with Azure AD, Google Workspace or GitHub if relevant.

:::tip AWS ECS

To be able to use the AWS APIs within Windmill on ECS containers, just whitelist the following environment variables in .env:
`WHITELIST_ENVS = "AWS_EXECUTION_ENV,AWS_CONTAINER_CREDENTIALS_RELATIVE_URI,AWS_DEFAULT_REGION,AWS_REGION"`
:::

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Workers and worker groups"
		description="Worker Groups allow users to run scripts and flows on different machines with varying specifications."
		href="/docs/core_concepts/worker_groups"
	/>
	<DocCard
		title="Windmill on AWS EKS or ECS"
		description="Windmill can also be deployed on AWS EKS or ECS"
		href="/docs/advanced/self_host/aws_eks_ecs"
	/>
</div>

### Ubicloud

Ubicloud provides cost-efficient managed Kubernetes and Postgresql. They are a great compromise if you are cost sensitive but still want to get a multi-node Kubernetes Windmill setup. And they are open-source too as an infra layer on top of other cloud providers.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Ubicloud"
		description="Ubicloud Community-Contributed Guide."
		href="https://www.ubicloud.com/docs/managed-kubernetes/windmill-tutorial"
		target="_blank"
	/>
</div>

### Fly.io

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Fly.io"
		description="Fly.io Community-Contributed Guide."
		href="https://dev.to/singee/deploy-windmill-on-flyio-3ii3"
		target="_blank"
	/>
</div>

### Render.com
<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Render.com"
		description="Render.com Setup Guide."
		href="https://github.com/alpetric/wmilll_render"
		target="_blank"
	/>
</div>

### Hetzner, Fargate, Digital Ocean, Linode, Scaleway, Vultr, OVH, ...

Windmill works with those providers using the [Docker containers](#docker) and specific guides are in progress.
