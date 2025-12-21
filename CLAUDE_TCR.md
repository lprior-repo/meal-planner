# CLAUDE_TCR.md - Test, Commit, Revert Discipline

## TCR OVERVIEW

**TCR = Test + Commit + Revert cycle**
**Purpose:** Guarantee correctness, avoid broken code on branch
**Cycle Time:** seconds to minutes per test-driven feature
**Discipline Level:** MANDATORY (Rule #3 in CLAUDE.md)

---

## THE THREE PHASES

### PHASE 1: RED (Test Fails)
```
Responsibility: TESTER
Action: Write ONE failing test
Constraint: Must fail for the correct reason (not syntax error)
Example: test/handlers_test.gleam -> case get_exercise(123)
  expect Ok(exercise) but got Error(NotFound)
```

### PHASE 2: GREEN (Test Passes)
```
Responsibility: CODER
Action: Implement minimal code to make test pass
Constraint: "Fake it till you make it" - no over-engineering
Example: Hardcode return value if needed, just pass the test
```

### PHASE 3: BLUE (Refactor)
```
Responsibility: REFACTORER
Action: Optimize syntax, structure, readability
Constraint: NO behavior change - test still passes
Example: Extract helper, inline duplication, improve naming
```

---

## THE CYCLE

```
1. WRITE TEST
   └─> Test fails (RED)
       └─> Why? [Correct reason? No? Fix test first]

2. IMPLEMENT
   └─> Test passes (GREEN)
       └─> Yes? → Continue
       └─> No? → REVERT (see REVERT PROTOCOL below)

3. REFACTOR (optional for simple code)
   └─> Test still passes (BLUE)
       └─> Yes? → COMMIT
       └─> No? → Undo refactor, keep code as-is

4. COMMIT
   └─> git commit -m "PASS: {{Behavior}}"

5. REPEAT for next test
```

---

## STRICT TCR MODE: Single Task

### Sequence (Simple Feature)
```
TASK: bd-1234 "Add login handler"

1. ARCHITECT (pre-work, optional)
   └─> Define LoginRequest, LoginResponse types
   └─> Create test/fixtures/valid_login.json

2. TESTER (RED PHASE)
   └─> Write test/login_test.gleam:
       pub fn login_success_test() {
         let req = LoginRequest(email: "user@example.com", password: "pass123")
         login(req)
         |> should.equal(Ok(LoginResponse(token: "abc123")))
       }
   └─> Run: gleam test
   └─> Expect FAILURE (test fails, no implementation yet)
   └─> If test doesn't fail: FIX TEST (wrong assertion? wrong data?)

3. CODER (GREEN PHASE)
   └─> Write src/login.gleam:
       pub fn login(req: LoginRequest) -> Result(LoginResponse, LoginError) {
         Ok(LoginResponse(token: "hardcoded_token"))  // FAKE IT
       }
   └─> Run: gleam test
   └─> Expect PASS (test passes)
   └─> If test fails: REVERT (git reset --hard) → Try different approach

4. REFACTORER (BLUE PHASE, optional)
   └─> Review implementation
   └─> Can we improve without changing behavior?
       └─> Extract validate_password() helper
       └─> Improve error messages
       └─> Use better naming
   └─> Run: gleam test
   └─> Still passing? → Keep changes
   └─> Test fails? → Undo refactor

5. COMMIT
   └─> git add -A
   └─> git commit -m "PASS: Login handler returns token on valid credentials"

6. NEXT TEST
   └─> TESTER writes test for: login fails with invalid password
   └─> Cycle repeats
```

---

## REVERT PROTOCOL

### Single Revert (Normal)
```
TRIGGER: Test fails after CODER implements

CODER implementation didn't work
├─> Check: Does test pass with this code? NO
├─> Action: git reset --hard (delete the bad code)
├─> Analysis: Why did it fail?
│   ├─> Test too strict? → TESTER adjusts test, goes back to RED
│   ├─> Logic wrong? → CODER tries different approach
│   ├─> Type mismatch? → Check if type definition needs changing (ARCHITECT domain)
└─> Next: TESTER → RED phase again

CONSTRAINT: Do not debug in place. REVERT and restart.
```

### Multiple Reverts (3+ on same behavior)
```
TRIGGER: Same CODER reverts 3 times on same test

Scenario:
├─> Attempt 1: Implementation X → Revert
├─> Attempt 2: Implementation Y → Revert
├─> Attempt 3: Implementation Z → Revert
└─> Now what?

ACTION: PAUSE_AND_REASSESS (IMPASSE_HANDLING)
├─> STOP all coding
├─> Lock the symbol (serena_lock_symbol)
├─> ARCHITECT reviews type definition
│   └─> Is the type correct? Constraints valid?
├─> TESTER reviews test
│   └─> Is test assertion correct? Test data valid?
├─> CODER plans new strategy
│   └─> Why did all 3 attempts fail?
│   └─> What assumption was wrong?
│   └─> What's a completely different approach?
└─> Next: Attempt 4 with NEW strategy

MULTI_AGENT: If one CODER stuck, others continue work on different symbols.
Unlock and retry when fresh.
```

---

## COMMIT RULES

### Commit ONLY After GREEN
```
✅ DO: Commit when test passes
git commit -m "PASS: Login returns token on valid credentials"

❌ DON'T: Commit when test fails
# Don't commit broken code

❌ DON'T: Commit without tests
# Features must have tests
```

### Commit Message Format
```
PASS: {{Behavior}}

Examples:
git commit -m "PASS: Login handler returns token on valid credentials"
git commit -m "PASS: Exercise query finds by ID with pagination"
git commit -m "PASS: Encoder handles nil bio field gracefully"

REFACTOR: {{Optimization}}
git commit -m "REFACTOR: Consolidate error handling in handlers"
git commit -m "REFACTOR: Extract pagination helper function"
```

### Commit Atomicity
```
ONE TEST = ONE COMMIT

✅ DO: Small commits
git commit -m "PASS: login returns token"
git commit -m "PASS: login rejects invalid password"
git commit -m "PASS: login rate limits after 5 failures"

❌ DON'T: Big commits
git commit -m "PASS: All login tests pass"  # Vague, hard to revert
```

---

## TESTING DISCIPLINE

### Test Requirements

1. **Test must fail first (RED)**
   ```
   ✅ Run before implementing
   gleam test
   → 1 test FAILED (for the correct reason)
   ```

2. **Test must pass after implementation (GREEN)**
   ```
   ✅ Run after implementing
   gleam test
   → 1 test PASSED
   ```

3. **Test must stay passing after refactor (BLUE)**
   ```
   ✅ Run after refactoring
   gleam test
   → 1 test PASSED (behavior unchanged)
   ```

4. **All tests pass before pushing (FINAL)**
   ```
   ✅ Before git push
   make test  # Parallel, fast
   → All tests PASSED (no regressions)
   ```

### Test Isolation
```
✅ DO: Independent tests
Each test should:
  - Setup its own data
  - Not depend on other tests
  - Clean up after itself
  - Be deterministic (same input → same output)

✅ DO: Use fixtures
test/fixtures/valid_user.json
test/fixtures/invalid_request.json

❌ DON'T: Shared state between tests
Don't modify global variables
Don't depend on test execution order
```

### Test Coverage
```
✅ DO: Test happy path AND error paths
pub fn login(req: LoginRequest) -> Result(LoginResponse, LoginError)
├─> Test 1: Valid credentials → Ok
├─> Test 2: Invalid password → Error(InvalidPassword)
├─> Test 3: User not found → Error(NotFound)
└─> Test 4: Empty email → Error(InvalidInput)

❌ DON'T: Test only happy path
pub fn login_success_test() { }
# Where are the error path tests?
```

---

## WORKFLOW FOR MULTI-AGENT TCR

### Single Revert (Normal)
```
IF CODER_1 reverts on failed test:
  → Only CODER_1 reverts: git reset --hard
  → CODER_1 tries different approach
  → Other CODERs continue work (different symbols)
  → No blocking
```

### Multi-Revert (Same CODER, Same Symbol)
```
IF CODER_1 reverts 3 times on same symbol:
  → LOCK symbol (serena_lock_symbol)
  → STOP other agents from using this symbol
  → ARCHITECT + TESTER + CODER_1 pause and reassess
  → Review type definition (ARCHITECT)
  → Review test (TESTER)
  → New strategy (CODER_1)
  → Attempt 4
```

### Deadlock (Two CODERs want same symbol)
```
IF CODER_1 and CODER_2 both locked on same symbol:
  → Check priority: ARCHITECT > TESTER > CODER > REFACTORER
  → If both CODERs: check lock timestamp (who locked first?)
  → First agent continues, second agent yields
  → Second agent works on different symbol
  → After first agent unlocks, second agent retries
```

---

## STATE TRACKING

```
Current_Task: bd-1234
Active_Phase: GREEN (implementing)
Test_Status: FAILING (need implementation)
Commits: 0 (not yet GREEN)
Reverts: 0 (no failed attempts yet)
Gleam_Format: ✅ PASS (gleam format --check)
```

---

## COMMON SCENARIOS

### Scenario 1: Test Too Strict
```
TESTER writes:
pub fn get_user_test() {
  get_user(UserId(1))
  |> should.equal(Ok(User(name: "John", email: "john@example.com", age: 30)))
}

CODER implements and gets wrong result format
→ Test fails

TESTER realizes: Test expects exact match, but User struct has optional fields
→ TESTER adjusts test to match actual structure
→ Both go back to RED → GREEN cycle

LESSON: Test and implementation should be designed together (ARCHITECT defines types)
```

### Scenario 2: Type Definition Wrong
```
ARCHITECT defines:
pub type LoginRequest { LoginRequest(email: String, password: String) }

TESTER writes test using this type

CODER implements but realizes:
→ Email needs validation (not just String)
→ Password needs length check (not just String)

CODER can't implement properly without changing type
→ Lock symbol (serena_lock_symbol src/types.gleam login_request)
→ ARCHITECT refines type: pub opaque type Email, pub opaque type Password
→ Unlock
→ CODER tries again with better types

LESSON: ARCHITECT phase is critical. Get types right first.
```

### Scenario 3: External API Call
```
TESTER writes test that calls external HTTP API
Test passes locally but fails in CI

ROOT CAUSE: Test shouldn't hit real API
SOLUTION: Mock the dependency

REFACTOR: Extract HTTP layer, inject mock in test
```

---

## CHECKLIST: Before Commit

- [ ] Test written first (RED phase completed)
- [ ] Implementation done (GREEN phase completed)
- [ ] All tests pass: `make test`
- [ ] Code formatted: `gleam format --check`
- [ ] No compiler warnings
- [ ] Behavior unchanged from previous refactor (if BLUE phase done)
- [ ] Commit message is clear and specific
- [ ] One atomic change per commit

---

## QUICK REFERENCE

```
Red → Green → Blue → Commit → Repeat

Single Revert?     → Try different approach
Triple Revert?     → PAUSE AND REASSESS
All Tests Pass?    → Ready to push
Format Check Fail?  → Run gleam format
Test Isolation?    → Each test independent
Behavior Changed?  → Was it intentional? (Refactor should not change behavior)
```

---

**TCR is ruthless. No broken code. No half-finished features. No guessing. Pass tests or revert.**
