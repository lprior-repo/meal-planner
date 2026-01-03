---
doc_id: ops/tandoor/guidelines
chunk_id: ops/tandoor/guidelines#chunk-3
heading_path: ["Guidelines", "Linting & Formatting"]
chunk_type: prose
tokens: 110
summary: "Linting & Formatting"
---

## Linting & Formatting

Tandoor uses a number of libraries to maintain style and formatting consistency.
To contribute to the project you are required to use the following packages with the project defined configurations:

- flake8
- yapf
- isort
- prettier

<!-- prettier-ignore -->
!!! tip "Manual Formatting"
     It is possible to run formatting manually, but it is recommended to setup your IDE to format on save.
     ``` bash
     flake8 file.py --ignore=E501 | isort -q file.py | yapf -i file.py
     prettier --write file.vue
    ```
