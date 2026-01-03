---
doc_id: ops/moonrepo/ci-2
chunk_id: ops/moonrepo/ci-2#chunk-14
heading_path: ["Continuous integration (CI)", "..."]
chunk_type: prose
tokens: 42
summary: "..."
---

## ...
env:
  global:
    - TRAVIS_JOB_TOTAL=2
  jobs:
    - TRAVIS_JOB_INDEX=0
    - TRAVIS_JOB_INDEX=1
script: 'moon ci --job $TRAVIS_JOB_INDEX --jobTotal $TRAVIS_JOB_TOTAL'
```

- [Documentation](https://docs.travis-ci.com/user/speeding-up-the-build/)

> Your CI environment may provide environment variables for these 2 values.
