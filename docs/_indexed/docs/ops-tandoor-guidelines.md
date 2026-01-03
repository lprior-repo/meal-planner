---
id: ops/tandoor/guidelines
title: "Guidelines"
category: ops
tags: ["guidelines", "tandoor", "operations"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>Guidelines</title>
  <description>If you want to contribute bug fixes or small tweaks then your pull requests are always welcome!</description>
  <created_at>2026-01-02T19:55:27.242689</created_at>
  <updated_at>2026-01-02T19:55:27.242689</updated_at>
  <language>en</language>
  <sections count="6">
    <section name="License" level="2"/>
    <section name="Linting &amp; Formatting" level="2"/>
    <section name="Testing" level="2"/>
    <section name="API Client" level="2"/>
    <section name="Vue" level="3"/>
    <section name="Install and Configuration" level="2"/>
  </sections>
  <features>
    <feature>api_client</feature>
    <feature>install_and_configuration</feature>
    <feature>license</feature>
    <feature>linting_formatting</feature>
    <feature>testing</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/contribute/vscode</entity>
    <entity relationship="uses">/contribute/pycharm</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>guidelines,tandoor,operations</tags>
</doc_metadata>
-->

# Guidelines

> **Context**: If you want to contribute bug fixes or small tweaks then your pull requests are always welcome!

If you want to contribute bug fixes or small tweaks then your pull requests are always welcome!

<!-- prettier-ignore-start -->
!!! danger "Discuss First!"
     If you want to contribute larger features that introduce more complexity to the project please
     make sure to **first submit a technical description** outlining what and how you want to do it.
     This allows me and the community to give feedback and manage the complexity of the overall
     application. If you don't do this please don't be mad if I reject your PR.
<!-- prettier-ignore-end -->

## License

Contributing to Tandoor requires signing a Contributor License Agreement. You can review the CLA [here](https://cla-assistant.io/TandoorRecipes/recipes).

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

## Testing

Django uses pytest-django to implement a full suite of testing. If you make any functional changes, please implement the appropriate
tests.

Tandoor is also actively soliciting contributors willing to setup vue3 testing. If you have knowledge in this area it would be greatly appreciated.

## API Client

<!-- prettier-ignore -->
!!! note "JAVA required"
     The OpenAPI Generator is a Java project. You must have the java binary executable available on your PATH for this to work.

Tandoor uses [django-rest-framework](https://www.django-rest-framework.org/) for API implementation. Making contributions that impact the API requires an understanding of
ViewSets and Serializers.

The API Client is generated automatically from the OpenAPI interface provided by the Django REST framework.
For this [openapi-generator](https://github.com/OpenAPITools/openapi-generator) is used.

Install it using your desired setup method. (For example, using `npm install @openapitools/openapi-generator-cli -g`.)

### Vue

Generate the schema using the `generate_api_client.py` script in the main directory. 

## Install and Configuration

Instructions for [VSCode](/contribute/vscode)
Instructions for [PyCharm](/contribute/pycharm)


## See Also

- [VSCode](/contribute/vscode)
- [PyCharm](/contribute/pycharm)
