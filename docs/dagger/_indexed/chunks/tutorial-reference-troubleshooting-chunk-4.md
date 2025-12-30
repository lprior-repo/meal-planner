---
doc_id: tutorial/reference/troubleshooting
chunk_id: tutorial/reference/troubleshooting#chunk-4
heading_path: ["troubleshooting", "Dagger restarts with a \"CNI setup error\""]
chunk_type: mixed
tokens: 46
summary: "The Dagger Engine requires the `iptable_nat` Linux kernel module."
---
The Dagger Engine requires the `iptable_nat` Linux kernel module.

**Solution:** Load this module:

```bash
sudo modprobe iptable_nat
```

To have this module loaded automatically on startup:

```bash
echo iptable_nat | sudo tee -a /etc/modules-load.d/iptables_nat.conf
```
