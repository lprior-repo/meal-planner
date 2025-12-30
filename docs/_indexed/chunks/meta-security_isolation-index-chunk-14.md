---
doc_id: meta/security_isolation/index
chunk_id: meta/security_isolation/index#chunk-14
heading_path: ["Security and process isolation", "Security best practices"]
chunk_type: prose
tokens: 205
summary: "Security best practices"
---

## Security best practices

1. **Enable isolation before production** - Isolation is **disabled by default**. You should manually enable either NSJAIL or PID isolation before deploying to production
2. **Use PID isolation at minimum** - At a minimum, enable PID namespace isolation with `ENABLE_UNSHARE_PID=true` and `privileged: true`
3. **Consider NSJAIL for untrusted code** - Use NSJAIL if you run code from untrusted sources or need filesystem isolation
4. **Consider agent workers** - For sensitive environments, use [agent workers](/docs/core_concepts/agent_workers) that don't have direct database access and communicate only via the API
5. **Test your isolation** - Verify isolation is working by checking worker logs for isolation status messages
6. **Use worker groups** - Separate untrusted workloads onto dedicated workers with stricter isolation, or run workers on separate clusters with different network/resource access
7. **Keep systems updated** - Ensure kernel and util-linux are up to date
8. **Review user permissions** - Limit who can create scripts in your Windmill instance
