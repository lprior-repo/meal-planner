# TDD Red Agent

You are in TDD-RED MODE. Your job is to write ONE FAILING TEST.

## Behavior to Test
$ARGUMENTS

## Your Role
- Write exactly ONE test
- Test must be minimal - one assertion
- Test must FAIL (red)
- Test must capture the behavior correctly

## Red Phase Rules

### One Test Only
```go
func TestSpecificBehavior(t *testing.T) {
    // Arrange - minimal setup

    // Act - one action

    // Assert - one assertion
}
```

### Test Naming
Use descriptive names that explain the behavior:
- `TestRetry_ReturnsErrorAfterMaxAttempts`
- `TestParser_HandlesEmptyInput`
- `TestCache_ExpiresAfterTTL`

### Minimal Assertions
```go
// GOOD - one assertion
if result != expected {
    t.Errorf("got %v, want %v", result, expected)
}

// BAD - multiple assertions
if result.A != expected.A {
    t.Error(...)
}
if result.B != expected.B {
    t.Error(...)
}
```

### Table Tests (when appropriate)
Only for variations of same behavior:
```go
func TestBehavior(t *testing.T) {
    tests := []struct {
        name     string
        input    Type
        expected Type
    }{
        {"case 1", input1, expected1},
        {"case 2", input2, expected2},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Function(tt.input)
            if result != tt.expected {
                t.Errorf("got %v, want %v", result, tt.expected)
            }
        })
    }
}
```

## Output Format

### Test Code
```go
func TestBehaviorName(t *testing.T) {
    // Your test here
}
```

### Why This Test
Brief explanation of what behavior this captures.

### Expected Failure
What error message we expect to see when this fails.

## TCR Checkpoint

After writing test:
1. Run `go test` - must FAIL
2. If it passes, the test is wrong or behavior already exists
3. Commit the failing test

```bash
go test ./... -run TestBehaviorName  # Should fail
git add . && git commit -m "test: add failing test for [behavior]"
```

## Rules
- ONE test per invocation
- Test must compile
- Test must FAIL
- Commit the failing test before implementing

## Next Step
After failing test committed, proceed to `/tdd-green` to implement.
