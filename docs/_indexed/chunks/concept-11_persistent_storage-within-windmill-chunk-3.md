---
doc_id: concept/11_persistent_storage/within-windmill
chunk_id: concept/11_persistent_storage/within-windmill#chunk-3
heading_path: ["Within Windmill: Not recommended", "Shared directory"]
chunk_type: prose
tokens: 228
summary: "Shared directory"
---

## Shared directory

For heavier ETL processes or sharing data between steps in a flow, Windmill provides a Shared Directory feature. This allows steps within a flow to share data by storing it in a designated folder at `./shared`.

:::caution
Although Shared Directories are recommended for persisting states within a flow, it's important to note that:

- All steps are executed on the same worker
- The data stored in the Shared Directory is strictly ephemeral to the flow execution
- The contents are not preserved across [suspends](./tutorial-flows-11-flow-approval.md) and [sleeps](./tutorial-flows-15-sleep.md)
  :::

To enable the Shared Directory:

1. Open the `Settings` menu in the Windmill interface
2. Go to the `Shared Directory` section
3. Toggle on the option for `Shared Directory on './shared'`

![Flow Shared Directory](../../assets/flows/flow_settings_shared_directory.png.webp)

Once enabled, steps can read and write files to the `./shared` folder to pass data between them. This is particularly useful for:

- Handling larger datasets that would be impractical to pass as step inputs/outputs
- Temporary storage of intermediate processing results
- Sharing files between steps in an ETL pipeline
