---
doc_id: ops/features/import-export
chunk_id: ops/features/import-export#chunk-23
heading_path: ["Import Export", "PDF"]
chunk_type: prose
tokens: 122
summary: "PDF"
---

## PDF

The PDF Exporter is an experimental feature that uses the puppeteer browser renderer to render each recipe and export it to PDF.
For that to work it downloads a chromium binary of about 140 MB to your server and then renders the PDF files using that.

Since that is something some server administrators might not want there the PDF exporter is disabled by default and can be enabled with `ENABLE_PDF_EXPORT=1` in `.env`.

See [this issue](https://github.com/TandoorRecipes/recipes/pull/1211) for more discussion on this and
[this issue](https://github.com/TandoorRecipes/recipes/issues/781) for the future plans to support server side rendering.
