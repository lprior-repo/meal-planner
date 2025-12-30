---
doc_id: meta/29_oidc/index
chunk_id: meta/29_oidc/index#chunk-1
heading_path: ["OpenID Connect (OIDC)"]
chunk_type: prose
tokens: 167
summary: "import Tabs from '@theme/Tabs';"
---

import Tabs from '@theme/Tabs';
import TabItem from '@theme/TabItem';

# OpenID Connect (OIDC)

> **Context**: import Tabs from '@theme/Tabs'; import TabItem from '@theme/TabItem';

Use Windmill's OIDC provider to authenticate from scripts to cloud providers and other APIs.

OIDC is an [EE feature only](/pricing).

Windmill OpenID Connect (OIDC) allows your scripts to authenticate to other APIs (such as AWS, GCP, or your own API) without having to store sensitive, long-lived credentials.
Your Windmill scripts can generate short-lived ID tokens which are passed to a target API to authenticate and "prove" their identity. ID tokens contain subject and claim information specific to the script, flow or worker, allowing for fine-grained access control (e.g. allowing specific scripts to access AWS buckets).
This page documents how to generate Windmill tokens and the token format.
