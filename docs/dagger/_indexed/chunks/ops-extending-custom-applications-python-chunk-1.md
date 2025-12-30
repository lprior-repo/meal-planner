---
doc_id: ops/extending/custom-applications-python
chunk_id: ops/extending/custom-applications-python#chunk-1
heading_path: ["custom-applications-python"]
chunk_type: code
tokens: 545
summary: "> **Context**: > **Note:** The Dagger Python SDK requires [Python 3."
---
# Python Custom Application

> **Context**: > **Note:** The Dagger Python SDK requires [Python 3.10 or later](https://docs.python.org/3/using/index.html).


> **Note:** The Dagger Python SDK requires [Python 3.10 or later](https://docs.python.org/3/using/index.html).

Install the Dagger Python SDK in your project:

```bash
uv add dagger-io
```

If you prefer, you can alternatively add the Dagger Python SDK in your Python program. This is useful in case of dependency conflicts, or to keep your Dagger code self-contained.

```bash
uv add --script myscript.py dagger-io
```

This example demonstrates how to test a Python application against multiple Python versions using the Python SDK.

Clone an example project:

```bash
git clone --branch 0.101.0 https://github.com/tiangolo/fastapi
cd fastapi
```

Create a new file named `test.py` in the project directory and add the following code to it.

```python
"""Run tests for multiple Python versions concurrently."""

import sys

import anyio

import dagger
from dagger import dag


async def test():
    versions = ["3.8", "3.9", "3.10", "3.11"]

    async with dagger.connection(dagger.Config(log_output=sys.stderr)):
        # get reference to the local project
        src = dag.host().directory(".")

        async def test_version(version: str):
            python = (
                dag.container()
                .from_(f"python:{version}-slim-buster")
                # mount cloned repository into image
                .with_directory("/src", src)
                # set current working directory for next commands
                .with_workdir("/src")
                # install test dependencies
                .with_exec(["pip", "install", "-r", "requirements.txt"])
                # run tests
                .with_exec(["pytest", "tests"])
            )

            print(f"Starting tests for Python {version}")

            # execute
            await python.sync()

            print(f"Tests for Python {version} succeeded!")

        # when this block exits, all tasks will be awaited (i.e., executed)
        async with anyio.create_task_group() as tg:
            for version in versions:
                tg.start_soon(test_version, version)

    print("All tasks have finished")


anyio.run(test)
```

This Python program imports the Dagger SDK and defines an asynchronous function named `test()`. This `test()` function creates a Dagger client, which provides an interface to the Dagger API. It also defines the test matrix, consisting of Python versions `3.8` to `3.11` and iterates over this matrix, downloading a Python container image for each specified version and testing the source application in that version.

Add the dependency:

```bash
uv add --script test.py dagger-io
```

Run the Python program by executing the command below from the project directory:

```bash
dagger run uv run test.py
```

The `dagger run` command executes the specified command in a Dagger session and displays live progress. The tool tests the application against each version concurrently and displays the following final output:

```
Starting tests for Python 3.8
Starting tests for Python 3.9
Starting tests for Python 3.10
Starting tests for Python 3.11
Tests for Python 3.8 succeeded!
Tests for Python 3.9 succeeded!
Tests for Python 3.11 succeeded!
Tests for Python 3.10 succeeded!
All tasks have finished
```
