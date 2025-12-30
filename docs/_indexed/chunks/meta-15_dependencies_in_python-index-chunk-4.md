---
doc_id: meta/15_dependencies_in_python/index
chunk_id: meta/15_dependencies_in_python/index#chunk-4
heading_path: ["Dependencies in Python", "Other"]
chunk_type: prose
tokens: 114
summary: "Other"
---

## Other

Other tricks can be used: [Sharing common logic with relative imports](#sharing-common-logic-with-relative-imports), [Pinning dependencies and requirements](#pinning-dependencies-and-requirements) and [Private PyPI Repository](#private-pypi-repository). All are compatible with the methods described above.

### Sharing common logic with relative imports

If you want to share common logic with Relative Imports, this can be done easily using [relative imports](./meta-5_sharing_common_logic-index.md) in both Python and TypeScript.

It is possible to import directly from other Python scripts. One can simply
follow the path layout. For instance,
`import foo from f.<foldername>.script_name`. A more complete example below:

```python
