---
doc_id: ops/cookbook/errors
chunk_id: ops/cookbook/errors#chunk-5
heading_path: ["errors", "Continue using a container after command execution fails"]
chunk_type: code
tokens: 489
summary: "```python
import dagger
from dagger import DaggerError, dag, field, function, object_type

SCRIPT..."
---
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
