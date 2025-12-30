# Errors and Debugging

This page contains practical examples for handling and debugging errors in Dagger workflows.

## Terminate gracefully

The following Dagger Function demonstrates how to handle errors in a workflow.

### Go

```go
package main

import (
	"context"
	"errors"
	"fmt"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

// Generate an error
func (m *MyModule) Test(ctx context.Context) (string, error) {
	out, err := dag.
		Container().
		From("alpine").
		// ERROR: cat: read error: Is a directory
		WithExec([]string{"cat", "/"}).
		Stdout(ctx)

	var e *dagger.ExecError
	if errors.As(err, &e) {
		return fmt.Sprintf("Test pipeline failure: %s", e.Stderr), nil
	} else if err != nil {
		return "", err
	}

	return out, nil
}
```

### Python

```python
from dagger import DaggerError, dag, function, object_type

@object_type
class MyModule:
    @function
    async def test(self) -> str:
        """Generate an error"""
        try:
            return await (
                dag.container()
                .from_("alpine")
                # ERROR: cat: read error: Is a directory
                .with_exec(["cat", "/"])
                .stdout()
            )
        except DaggerError as e:
            # DaggerError is the base class for all errors raised by dagger
            return "Test pipeline failure: " + e.stderr
```

### TypeScript

```typescript
import { dag, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  /**
   * Generate an error
   */
  @func()
  async test(): Promise<string> {
    try {
      return await dag
        .container()
        .from("alpine")
        // ERROR: cat: read error: Is a directory
        .withExec(["cat", "/"])
        .stdout()
    } catch (e) {
      return `Test pipeline failure: ${e.stderr}`
    }
  }
}
```

### Example

Execute a Dagger Function which creates a container and runs a command in it. If the command fails, the error is captured and the Dagger Function is gracefully terminated with a custom error message.

```bash
dagger call test
```

## Continue using a container after command execution fails

The following Dagger Function demonstrates how to continue using a container after a command executed within it fails. A common use case for this is to export a report that a test suite tool generates.

> **Note**: The caveat with this approach is that forcing a zero exit code on a failure caches the failure. This may not be desired depending on the use case.

### Go

```go
package main

import (
	"context"
	"fmt"

	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

var script = `#!/bin/sh
echo "Test Suite"
echo "=========="
echo "Test 1: PASS" | tee -a report.txt
echo "Test 2: FAIL" | tee -a report.txt
echo "Test 3: PASS" | tee -a report.txt
exit 1`

type TestResult struct {
	Report   *dagger.File
	ExitCode int
}

// Handle errors
func (m *MyModule) Test(ctx context.Context) (*TestResult, error) {
	ctr, err := dag.
		Container().
		From("alpine").
		// add script with execution permission to simulate a testing tool
		WithNewFile("/run-tests", script, dagger.ContainerWithNewFileOpts{Permissions: 0o750}).
		// run-tests but allow any return code
		WithExec([]string{"/run-tests"}, dagger.ContainerWithExecOpts{Expect: dagger.ReturnTypeAny}).
		// the result of `sync` is the container, which allows continued chaining
		Sync(ctx)
	if err != nil {
		// unexpected error, could be network failure.
		return nil, fmt.Errorf("run tests: %w", err)
	}

	// save report for inspection.
	report := ctr.File("report.txt")

	// use the saved exit code to determine if the tests passed.
	exitCode, err := ctr.ExitCode(ctx)
	if err != nil {
		// exit code not found
		return nil, fmt.Errorf("get exit code: %w", err)
	}

	// Return custom type
	return &TestResult{
		Report:   report,
		ExitCode: exitCode,
	}, nil
}
```

### Python

```python
import dagger
from dagger import DaggerError, dag, field, function, object_type

SCRIPT = """#!/bin/sh
echo "Test Suite"
echo "=========="
echo "Test 1: PASS" | tee -a report.txt
echo "Test 2: FAIL" | tee -a report.txt
echo "Test 3: PASS" | tee -a report.txt
exit 1"""

@object_type
class TestResult:
    report: dagger.File = field()
    exit_code: int = field()

@object_type
class MyModule:
    @function
    async def test(self) -> TestResult:
        """Handle errors"""
        try:
            ctr = await (
                dag.container()
                .from_("alpine")
                # add script with execution permission to simulate a testing tool.
                .with_new_file("/run-tests", SCRIPT, permissions=0o750)
                # run-tests but allow any return code
                .with_exec(["/run-tests"], expect=dagger.ReturnType.ANY)
                # the result of `sync` is the container, which allows continued chaining
                .sync()
            )

            # save report for inspection.
            report = ctr.file("report.txt")

            # use the saved exit code to determine if the tests passed.
            exit_code = await ctr.exit_code()

            return TestResult(report=report, exit_code=exit_code)
        except DaggerError as e:
            # DaggerError is the base class for all errors raised by Dagger
            msg = "Unexpected Dagger error"
            raise RuntimeError(msg) from e
```

### TypeScript

```typescript
import { dag, object, func, File, ReturnType } from "@dagger.io/dagger"

const SCRIPT = `#!/bin/sh
echo "Test Suite"
echo "=========="
echo "Test 1: PASS" | tee -a report.txt
echo "Test 2: FAIL" | tee -a report.txt
echo "Test 3: PASS" | tee -a report.txt
exit 1`

@object()
class TestResult {
  @func()
  report: File

  @func()
  exitCode: number
}

@object()
class MyModule {
  /**
   * Handle errors
   */
  @func()
  async test(): Promise<TestResult> {
    const ctr = await dag
      .container()
      .from("alpine")
      // add script with execution permission to simulate a testing tool.
      .withNewFile("/run-tests", SCRIPT, { permissions: 0o750 })
      // run-tests but allow any return code
      .withExec(["/run-tests"], { expect: ReturnType.Any })
      // the result of `sync` is the container, which allows continued chaining
      .sync()

    const result = new TestResult()
    // save report for inspection.
    result.report = ctr.file("report.txt")
    // use the saved exit code to determine if the tests passed
    result.exitCode = await ctr.exitCode()

    return result
  }
}
```

### Example

Continue executing a Dagger Function even after a command within it fails. The Dagger Function returns a custom `TestResult` object containing a test report and the exit code of the failed command.

Obtain the exit code:

```bash
dagger call test exit-code
```

Obtain the report:

```bash
dagger call test report contents
```

## Debug workflows with the interactive terminal

Dagger provides two features that can help greatly when trying to debug a workflow - opening an interactive terminal session at the failure point, or at explicit breakpoints throughout your workflow code. All context is available at the point of failure. Multiple terminals are supported in the same Dagger Function; they will open in sequence.

The following Dagger Function opens an interactive terminal session at different stages in a Dagger workflow to debug a container build.

### Go

```go
package main

import (
	"dagger/my-module/internal/dagger"
)

type MyModule struct{}

func (m *MyModule) Container() *dagger.Container {
	return dag.Container().
		From("alpine:latest").
		Terminal().
		WithExec([]string{"sh", "-c", "echo hello world > /foo && cat /foo"}).
		Terminal()
}
```

### Python

```python
import dagger
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    def container(self) -> dagger.Container:
        return (
            dag.container()
            .from_("alpine:latest")
            .terminal()
            .with_exec(["sh", "-c", "echo hello world > /foo && cat /foo"])
            .terminal()
        )
```

### TypeScript

```typescript
import { dag, Container, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  @func()
  container(): Container {
    return dag
      .container()
      .from("alpine:latest")
      .terminal()
      .withExec(["sh", "-c", "echo hello world > /foo && cat /foo"])
      .terminal()
  }
}
```

### Example

Execute a Dagger Function to build a container, and open an interactive terminal at two different points in the build process. The interactive terminal enables you to inspect the container filesystem and environment "live", during the build process.

```bash
dagger call container
```

## Inspect directories and files

The following Dagger Function clones Dagger's GitHub repository and opens an interactive terminal session to inspect it. Under the hood, this creates a new container (defaults to `alpine`) and starts a shell, mounting the repository directory inside.

### Go

```go
package main

import (
  "context"
)

type MyModule struct{}

func (m *MyModule) SimpleDirectory(ctx context.Context) (string, error) {
	return dag.
		Git("https://github.com/dagger/dagger.git").
		Head().
		Tree().
		Terminal().
		File("README.md").
		Contents(ctx)
}
```

### Python

```python
from dagger import dag, function, object_type

@object_type
class MyModule:
    @function
    async def simple_directory(self) -> str:
        return await (
            dag.git("https://github.com/dagger/dagger.git")
            .head()
            .tree()
            .terminal()
            .file("README.md")
            .contents()
        )
```

### TypeScript

```typescript
import { dag, Container, object, func } from "@dagger.io/dagger"

@object()
class MyModule {
  @func()
  async simpleDirectory(): Promise<string> {
    return await dag
      .git("https://github.com/dagger/dagger.git")
      .head()
      .tree()
      .terminal()
      .file("README.md")
      .contents()
  }
}
```

### Example

Execute a Dagger Function to clone Dagger's GitHub repository and open a terminal session in the repository directory:

```bash
dagger call simple-directory
```

## Create custom spans

Dagger represents operations performed by a Dagger Function as OpenTelemetry spans. Spans are typically used to separate tasks that are running in parallel, with each branch waiting for completion.

It is possible to instrument custom OpenTelemetry spans inside any Dagger Function. This allows you to define logical boundaries within complex workflows, measure execution time, and track nested operations with greater granularity. These custom spans appear in the Dagger TUI and Traces.

> **Warning**: The approach described below is experimental and may be deprecated in favor of a new OpenTelemetry span API.

### Go

```go
package main

import (
	"context"
	"dagger/my-module/internal/telemetry"

	"golang.org/x/sync/errgroup"
)

type MyModule struct{}

func (m *MyModule) Foo(ctx context.Context) error {
	// clone the source code repository
	source := dag.
		Git("https://github.com/dagger/hello-dagger").
		Branch("main").Tree()

	// list versions to test against
	versions := []string{"20", "22", "23"}

	// define errorgroup
	eg := new(errgroup.Group)

	// run tests concurrently
	// emit a span for each
	for _, version := range versions {
		eg.Go(func() (rerr error) {
			ctx, span := Tracer().Start(ctx, "running unit tests with Node "+version)
			defer telemetry.End(span, func() error { return rerr })
			_, err := dag.Container().
				From("node:"+version).
				WithDirectory("/src", source).
				WithWorkdir("/src").
				WithExec([]string{"npm", "install"}).
				WithExec([]string{"npm", "run", "test:unit", "run"}).
				Sync(ctx)
			return err
		})
	}
	return eg.Wait()
}
```

### Python

```python
import anyio
from opentelemetry import trace

from dagger import dag, function, object_type

tracer = trace.get_tracer(__name__)

@object_type
class MyModule:
    @function
    async def foo(self):
        # clone the source code repository
        source = dag.git("https://github.com/dagger/hello-dagger").branch("main").tree()

        # list versions to test against
        versions = ["20", "22", "23"]

        async def _test(version: str):
            with tracer.start_as_current_span(
                f"running unit tests with Node {version}"
            ):
                await (
                    dag.container()
                    .from_(f"node:{version}")
                    .with_directory("/src", source)
                    .with_workdir("/src")
                    .with_exec(["npm", "install"])
                    .with_exec(["npm", "run", "test:unit", "run"])
                    .sync()
                )

        # run tests concurrently
        # emit a span for each
        async with anyio.create_task_group() as tg:
            for version in versions:
                tg.start_soon(_test, version)
```

### TypeScript

```typescript
import { dag, object, func } from "@dagger.io/dagger"
import * as trace from "@dagger.io/dagger/telemetry"

@object()
export class MyModule {
  @func()
  async foo(): Promise<void> {
    // clone the source code repository
    const source = dag
      .git("https://github.com/dagger/hello-dagger")
      .branch("main")
      .tree()

    // list versions to test against
    const versions = ["20", "22", "23"]

    const tracer = trace.getTracer(MyModule.name)

    // run tests concurrently
    // emit a span for each
    await Promise.all(
      versions.map(async (version) => {
        await tracer.startActiveSpan(
          `running unit tests with Node ${version}`,
          async () => {
            await dag
              .container()
              .from(`node:${version}`)
              .withDirectory("/src", source)
              .withWorkdir("/src")
              .withExec(["npm", "install"])
              .withExec(["npm", "run", "test:unit", "run"])
              .sync()
          },
        )
      }),
    )
  }
}
```

### Example

Execute a Dagger Function to run unit tests on the `dagger/hello-dagger` source code repository with different versions of Node.js, emitting a custom span for each version tested:

```bash
dagger call foo
```
