---
doc_id: meta/20_jobs/index
chunk_id: meta/20_jobs/index#chunk-4
heading_path: ["Jobs", "Job inputs and script parameters"]
chunk_type: prose
tokens: 170
summary: "Job inputs and script parameters"
---

## Job inputs and script parameters

Jobs take a JSON object as input which can be empty. That input is passed as the payload of the POST request that triggers the Script. The different key-value pairs of the objects are passed as the different parameters of the main function, with just a few language-specific transformations to more adequate types in the target language, if necessary (e.g base64/datetime encoding). Values can be nested JSON objects themselves, but we recommend trying to keep the input flat when possible.

If the payload contains keys that are not defined as parameters in the main function, they will be ignored. This allows you to handle arbitrary JSON payloads, as you can choose which keys to define as parameters in your script and process the data accordingly.
