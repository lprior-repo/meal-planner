---
doc_id: tutorial/reference/best-practices-modules
chunk_id: tutorial/reference/best-practices-modules#chunk-2
heading_path: ["best-practices-modules", "Module Tests"]
chunk_type: code
tokens: 315
summary: "Like any other piece of software, Dagger Functions and modules should be thoroughly tested."
---
Like any other piece of software, Dagger Functions and modules should be thoroughly tested.

### Test Module Pattern

Create a test module in the same directory as your main module:

```bash
mkdir tests
cd tests
dagger init --name=tests --sdk=go --source=.
dagger install ..
```

Then add your tests as Dagger Functions.

### Testable Examples

Example modules can be combined with the test module pattern to turn examples into executable tests:

```bash
mkdir -p examples/go
cd examples/go
dagger init --name=examples/go --sdk=go --source=.
dagger install ../..
```

### Test Function Signature

Standardize your test function signature:

**Go:**
```go
func (m *Tests) YourTest(ctx context.Context) error {
    // Your test here
    if false { // Your error condition here
        return errors.New("test failed")
    }
    return nil
}
```

**Python:**
```python
@function
async def your_test(self):
    # Your test here
    if false: # Your error condition here
        raise Exception("test failed")
```

**TypeScript:**
```typescript
@func()
hello(): Promise<void> {
    return dag
        .yourModule()
        .yourFunction()
        .then(() => {
            if (false) { // Your error condition here
                throw new Error("test failed");
            }
            return;
        });
}
```

### "All" Function Pattern

Create a single function that executes all your tests:

**Go (parallel):**
```go
func (m *Tests) All(ctx context.Context) error {
    p := pool.New().WithErrors().WithContext(ctx)
    p.Go(m.Hello)
    p.Go(m.CustomGreeting)
    return p.Wait()
}
```

**Python (parallel):**
```python
@function
async def all(self):
    async with anyio.create_task_group() as tg:
        tg.start_soon(self.first_test)
        tg.start_soon(self.second_test)
```

**TypeScript (parallel):**
```typescript
@func()
async all(): Promise<void> {
    await Promise.all([this.firstTest(), this.secondTest()]);
}
```

Run all tests: `dagger call -m tests all`
