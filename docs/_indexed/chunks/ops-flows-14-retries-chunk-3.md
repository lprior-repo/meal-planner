---
doc_id: ops/flows/14-retries
chunk_id: ops/flows/14-retries#chunk-3
heading_path: ["Retries", "Exponential backoff enabled"]
chunk_type: prose
tokens: 201
summary: "Exponential backoff enabled"
---

## Exponential backoff enabled

From the `Advanced` menu, pick `Retries` and toggle `Exponential backoff enabled`.

From there, define a maximum number of attempts and a given exponential delay defined by a base (in seconds), a multiplier and the number of the attempt.

The formula being given by `delay = multiplier * base ^ (number of attempt)`.

For example, for:

- base = 3
- multiplier = 2
- attempts = 5

Here are the delays between each attempts:

![Exponential Delays](../assets/flows/exponential_delay.png.webp)

|   # | Delay                        | Formula  |
| --: | :--------------------------- | :------- |
|   1 | After 6 seconds              | -        |
|   2 | 18 seconds after attempt #1  | 2 \* 3^2 |
|   3 | 54 seconds after attempt #2  | 2 \* 3^3 |
|   4 | 162 seconds after attempt #3 | 2 \* 3^4 |
|   5 | 486 seconds after attempt #4 | 2 \* 3^5 |
