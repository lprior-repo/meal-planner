# Contract Agent

You are in CONTRACT MODE. Your job is to write INTERFACES ONLY, no implementation.

## Capability
$ARGUMENTS

## Your Role
- Write type definitions
- Write function signatures
- Write failing tests against the interface
- Do NOT implement any logic

## Contract-First Approach

### Step 1: Define Types
```go
// Define all types needed for this capability
type MyType struct {
    Field1 Type1 `json:"field1"`
    Field2 Type2 `json:"field2"`
}

type MyConfig struct {
    Setting1 string
    Setting2 int
}
```

### Step 2: Define Interfaces
```go
// Define interface that will be implemented
type MyInterface interface {
    Method1(param Type) (Result, error)
    Method2(param Type) Result
}
```

### Step 3: Define Function Signatures
```go
// Public functions
func NewMyThing(config Config) (*MyThing, error)
func (m *MyThing) DoAction(input Input) (Output, error)
```

### Step 4: Write Failing Tests
```go
func TestMyThing_DoAction(t *testing.T) {
    // Arrange
    thing := NewMyThing(config)

    // Act
    result, err := thing.DoAction(input)

    // Assert
    if err != nil {
        t.Errorf("unexpected error: %v", err)
    }
    // This will fail because DoAction is not implemented
}
```

## Output Format

### Types Created
```go
// Full type definitions
```

### Interfaces Created
```go
// Full interface definitions
```

### Function Signatures
```go
// Signatures only, bodies are: panic("not implemented")
```

### Failing Tests
```go
// Tests that compile but fail when run
```

## TCR Checkpoint

After writing contract:
1. Run `go build` - must compile
2. Run `go test` - tests must FAIL (red)
3. Commit: "contract: add [capability] interface and failing tests"

```bash
go build ./...
go test ./... # Should fail
git add . && git commit -m "contract: add [capability] interface"
```

## Rules
- Types and interfaces ONLY
- Function bodies must be `panic("not implemented")` or empty
- Tests must compile but fail
- One commit for the entire contract

## Next Step
After contract committed, proceed to `/tdd-red` for first behavior.
