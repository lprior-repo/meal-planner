---
doc_id: ops/guides/offline-mode
chunk_id: ops/guides/offline-mode#chunk-1
heading_path: ["Offline mode"]
chunk_type: prose
tokens: 120
summary: "Offline mode"
---

# Offline mode

> **Context**: moon assumes that an internet connection is always available, as we download and install tools into the toolchain, resolve versions against upstream m

moon assumes that an internet connection is always available, as we download and install tools into the toolchain, resolve versions against upstream manifests, and automatically install dependencies. While this is useful, having a constant internet connection isn't always viable.

To support workflows where internet isn't available or is spotty, moon will automatically check for an active internet connection, and drop into offline mode if necessary.
