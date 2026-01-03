---
doc_id: ops/windmill/aws-eks-ecs
chunk_id: ops/windmill/aws-eks-ecs#chunk-2
heading_path: ["Windmill on AWS", "Windmill on AWS EKS"]
chunk_type: prose
tokens: 449
summary: "Windmill on AWS EKS"
---

## Windmill on AWS EKS
Windmill can be deployed on an EKS ([Elastic Kubernetes Service](https://aws.amazon.com/eks/)) cluster. Below are the detailed steps to get a Windmill stack up and running. The number of servers and [workers](./meta-windmill-index-80.md), as well as the instance sizes, should be tuned to your own usecases.

You can either setup your own EKS cluster and RDS instance and deploy Windmill using the [Helm chart](../self_host#helm-chart) or use the Cloudformation template below.

### Cloudformation
The [CloudFormation template](https://github.com/windmill-labs/windmill/tree/main/examples/deploy/aws-eks-cloudformation) automatically deploys Windmill on AWS EKS. The deployment includes:

- An EKS cluster with configurable node types and sizes
- An RDS PostgreSQL database for Windmill data
- AWS Load Balancer Controller for handling ingress traffic
- Proper network configuration with VPC, subnets, and security groups
- A fully automated installation of Windmill via Helm

### Parameters

The template accepts various parameters to customize your deployment:

- **NodeInstanceType**: EC2 instance type for EKS worker nodes (t3.small to r5.2xlarge)
- **NodeGroupSize**: Number of EKS worker nodes
- **RdsInstanceClass**: RDS instance class for the PostgreSQL database (db.t3.micro to db.r5.2xlarge)
- **DBPassword**: Password for the PostgreSQL database
- **WorkerReplicas**: Number of Windmill worker replicas
- **NativeWorkerReplicas**: Number of Windmill native worker replicas
- **Enterprise**: Enable Windmill [Enterprise features](https://www.windmill.dev/docs/misc/plans_details#upgrading-to-enterprise-edition) (requires license key)


To modify the Helm chart configuration or update the template, refer to the official [Windmill Helm chart repository](https://github.com/windmill-labs/windmill-helm-charts). For detailed information about a recommended setup for setting up RDS for Windmill on AWS, see [Windmill on AWS ECS](./aws_eks_ecs#create-a-rds-database) below.

### Deployment

1. Upload the CloudFormation template to your AWS account
2. Fill in the required parameters
3. Deploy the stack
4. Access Windmill using the URL provided in the Outputs section of the stack

After deployment, you can access Windmill via the LoadBalancer URL shown in the CloudFormation stack outputs.

:::tip
The Cloudformation template is a good option for a quick start. Once the installation is done, we recommend using the [Helm chart](../self_host#helm-chart) to manage your Windmill stack and also update the loadbalancer to use a custom domain name and SSL certificate as by default this deployment is HTTP only.
:::
