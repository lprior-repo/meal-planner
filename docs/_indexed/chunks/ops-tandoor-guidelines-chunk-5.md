---
doc_id: ops/tandoor/guidelines
chunk_id: ops/tandoor/guidelines#chunk-5
heading_path: ["Guidelines", "API Client"]
chunk_type: prose
tokens: 128
summary: "API Client"
---

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
