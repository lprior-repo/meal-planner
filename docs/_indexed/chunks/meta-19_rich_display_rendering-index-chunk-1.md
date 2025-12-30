---
doc_id: meta/19_rich_display_rendering/index
chunk_id: meta/19_rich_display_rendering/index#chunk-1
heading_path: ["Rich display rendering"]
chunk_type: prose
tokens: 725
summary: "import DocCard from '@site/src/components/DocCard';"
---

import DocCard from '@site/src/components/DocCard';

# Rich display rendering

> **Context**: import DocCard from '@site/src/components/DocCard';

Windmill processes some outputs (from scripts or flows) intelligently to provide rich display rendering, allowing you to customize the display format of your results.

By default, all results are displayed in a JSON format. However, some formats are recognised automatically ([Rich Table Display](#rich-table-display)), while others can be forced through your code. By leveraging specific keys, you can display images, files, tables, HTML, JSON, and more.

If the result is an object/dict with a single key (except for `resume`, which needs 3), you can leverage the following rich results:

| Type             | Description                                                 | Example                                                                                                              |
| ----------       | ----------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| [table-col](#table-column)        | Render the value as a column-wise table.                     | `return { "table-col": { "foo": [42, 8], "bar": [38, 12] } }`                                                        |
| [table-row](#table-row)        | Render the value as a row-wise table.                        | `return { "table-row": [ [ "foo", "bar" ], [ 42, 38 ], [ 8, 12 ] ] }`                                                |
| [table-row-object](#table-row-object) | Render the value as a row-wise table but where each row is an object. | `return { "table-row-object": [ { "foo": 42, "bar": 38 }, { "foo": 8, "bar": 12 } ] }` or  `return { "table-row-object": [ ["foo", "bar" ], { "foo": 42, "bar": 38 }, { "foo": 8, "bar": 12 } ] }` |
| [s3](#s3)               | Render S3 files as a downloadable file and a bucket explorer, when Windmill is [connected to a S3 storage](./meta-38_object_storage_in_windmill-index.md#workspace-object-storage).                                  | `return { "s3": "path_to_file"}`           |
| [html](#html)             | Render the value as HTML.                                    | `return { "html": "<div>...</div>" }`                                                                                |
| [markdown](#markdown)         | Render the value as Markdown.                                | `return { "markdown": "## Hello World\nNice to meet you" }` or `return { "md": "## Hello World\nNice to meet you" }`                                     |
| [file](#file)             | Render an option to download a file.                       | `return { "file": { "content": encode(file), "filename": "data.txt" } }`                                             |
| [pdf](#pdf)              | Render the value as a PDF document.                            | `return { "pdf": base64Pdf }`                               
| [png](#png)              | Render the value as a PNG image.                             | `return { "png": { "content": base64Image } }` or `return { "png": base64Image }`                                |
| [jpeg](#jpeg)             | Render the value as a JPEG image.                            | `return { "jpeg": { "content": base64Image } }` or `return { "jpeg": base64Image }`                              |
| [gif](#gif)              | Render the value as a GIF image.                             | `return { "gif": { "content": base64Image } }` or `return { "gif": base64Image }`                                |
| [svg](#svg)              | Render the value as an SVG image.                            | `return { "svg": "<svg>...</svg>" }`                                                                                 |
| [error](#error)            | Render the value as an error message.                        | `return { "error": { "name": "418", "message": "I'm a teapot", "stack": "Error: I'm a teapot" }}`                                                    |
| [resume](#resume)           | Render an approval and buttons to Resume or Cancel the step. | `return { "resume": "https://example.com", "cancel": "https://example.com", "approvalPage": "https://example.com" }` |
| [map](#map)              | Render a map with a given location.                                 | `return { "map": { lat: 40, lon: 0, zoom: 3, markers: [{lat: 50.6, lon: 3.1, title: "Home", radius: 5, color: "yellow", strokeWidth: 3, strokeColor: "Black"}]}}`           |
| [render_all](#render-all)       | Render all the results.                                      | `return { "render_all": [ { "json": { "a": 1 } }, { "table-col": { "foo": [42, 8], "bar": [38, 12] }} ] }`           |
