---
doc_id: concept/tandoor/automation
chunk_id: concept/tandoor/automation#chunk-3
heading_path: ["Automation", "Description Replace"]
chunk_type: prose
tokens: 278
summary: "Description Replace"
---

## Description Replace

This automation is a bit more complicated than the alias rules. It is run when importing a recipe
from a website.

It uses Regular Expressions (RegEx) to determine if a description should be altered, what exactly to remove
and what to replace it with.  The search string ignores case, the replacement string respects case.

-   **Parameter 1**: pattern of which sites to match (e.g. `.*.chefkoch.de.*`, `.*`)
-   **Parameter 2**: pattern of what to replace (e.g. `.*`)
-   **Parameter 3**: value to replace matched occurrence of parameter 2 with. Only the first occurrence of the pattern is replaced.

To replace the description the python [re.sub](https://docs.python.org/2/library/re.html#re.sub) function is used
like this `re.sub(<parameter 2>, <parameter 3>, <description>, count=1)`

To test out your patterns and learn about RegEx you can use [regexr.com](https://regexr.com/)
ChatGPT and similiar LLMs are also useful for creating RegEx patterns:
`ChatGPT please create a Regex expression in the format of re.sub(<parameter 2>, <parameter 3>, <description>, count=1)
that will change the string <example string here> into the string <desired result here>`

<!-- prettier-ignore -->
!!! info
    In order to prevent denial of service attacks on the RegEx engine the number of replace automations
    and the length of the inputs that are processed are limited. Those limits should never be reached
    during normal usage.
