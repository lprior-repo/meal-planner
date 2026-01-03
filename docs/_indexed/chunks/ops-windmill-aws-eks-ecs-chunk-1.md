---
doc_id: ops/windmill/aws-eks-ecs
chunk_id: ops/windmill/aws-eks-ecs#chunk-1
heading_path: ["Windmill on AWS"]
chunk_type: prose
tokens: 211
summary: "<!--"
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>windmill</category>
  <title>Windmill on AWS</title>
  <description>import DocCard from &apos;@site/src/components/DocCard&apos;; import Tabs from &apos;@theme/Tabs&apos;; import TabItem from &apos;@theme/TabItem&apos;;</description>
  <created_at>2026-01-02T19:55:27.430068</created_at>
  <updated_at>2026-01-02T19:55:27.430068</updated_at>
  <language>en</language>
  <sections count="22">
    <section name="Windmill on AWS EKS" level="2"/>
    <section name="Cloudformation" level="3"/>
    <section name="Parameters" level="3"/>
    <section name="Deployment" level="3"/>
    <section name="Windmill on AWS ECS" level="2"/>
    <section name="Create a VPC and a security group" level="3"/>
    <section name="Create a RDS database" level="3"/>
    <section name="Create the ECS cluster" level="3"/>
    <section name="Create a Load Balancer and Target Groups" level="3"/>
    <section name="Create the task definitions" level="3"/>
  </sections>
  <features>
    <feature>cloudformation</feature>
    <feature>create_a_rds_database</feature>
    <feature>create_a_vpc_and_a_security_group</feature>
    <feature>create_the_ecs_cluster</feature>
    <feature>create_the_services</feature>
    <feature>create_the_task_definitions</feature>
    <feature>deployment</feature>
    <feature>multi-purpose_windmill_worker</feature>
    <feature>native_windmill_worker</feature>
    <feature>open_windmill</feature>
    <feature>parameters</feature>
    <feature>windmill_lsp</feature>
    <feature>windmill_multi-purpose_worker</feature>
    <feature>windmill_multiplayer</feature>
    <feature>windmill_native_worker</feature>
  </features>
  <dependencies>
    <dependency type="service">postgres</dependency>
    <dependency type="service">postgresql</dependency>
    <dependency type="service">kubernetes</dependency>
    <dependency type="feature">meta/windmill/index-80</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">../../core_concepts/9_worker_groups/index.mdx</entity>
    <entity relationship="uses">../self_host</entity>
    <entity relationship="uses">./aws_eks_ecs</entity>
    <entity relationship="uses">../self_host</entity>
    <entity relationship="uses">../../core_concepts/9_worker_groups/index.mdx</entity>
  </related_entities>
  <examples count="5">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>19</estimated_reading_time>
  <tags>windmill,aws,advanced,operations</tags>
</doc_metadata>
-->

# Windmill on AWS

> **Context**: import DocCard from '@site/src/components/DocCard'; import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

import DocCard from '@site/src/components/DocCard';
import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';
