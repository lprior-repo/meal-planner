import type { Plugin } from "@opencode-ai/plugin"
import { tool } from "@opencode-ai/plugin"

/**
 * TDD Workflow Plugin
 * 
 * Provides tools and hooks for Test-Driven Development with TCR discipline:
 * - Phase tracking (red/green/refactor)
 * - Automatic test running
 * - Commit/revert automation
 * - Session metrics
 * 
 * Hooks:
 * - session.created: Initialize TDD state
 * - session.idle: Report session metrics
 * - tool.execute.after: Track test runs and commits
 * - command.executed: Track TDD commands
 */

// TDD Phase states
type TddPhase = "idle" | "red" | "green" | "refactor"

// State tracking
interface TddState {
  phase: TddPhase
  currentBehavior: string | null
  lastTestResult: "pass" | "fail" | null
  lastCommit: string | null
  sessionStats: {
    testsRun: number
    testsPass: number
    testsFail: number
    commits: number
    reverts: number
    behaviors: string[]
    startTime: Date | null
  }
}

const state: TddState = {
  phase: "idle",
  currentBehavior: null,
  lastTestResult: null,
  lastCommit: null,
  sessionStats: {
    testsRun: 0,
    testsPass: 0,
    testsFail: 0,
    commits: 0,
    reverts: 0,
    behaviors: [],
    startTime: null,
  },
}

export const TddWorkflowPlugin: Plugin = async ({ project, client, $, directory }) => {
  console.log("[tdd-workflow] Plugin initialized")

  // Helper: Run tests based on project type
  const runTests = async (): Promise<{ pass: boolean; output: string }> => {
    try {
      // Try Gleam first
      const gleamToml = await $`test -f gleam/gleam.toml && echo "gleam"`.text().catch(() => "")
      if (gleamToml.includes("gleam")) {
        const result = await $`cd gleam && gleam test 2>&1`.text()
        const pass = !result.includes("FAILED") && !result.includes("error:")
        return { pass, output: result }
      }

      // Fall back to Go
      const result = await $`go test ./... 2>&1`.text()
      const pass = result.includes("ok") && !result.includes("FAIL")
      return { pass, output: result }
    } catch (e: any) {
      return { pass: false, output: e.message || String(e) }
    }
  }

  // Helper: Get last commit hash
  const getLastCommit = async (): Promise<string> => {
    try {
      return (await $`git rev-parse --short HEAD`.text()).trim()
    } catch {
      return ""
    }
  }

  // Helper: Format duration
  const formatDuration = (ms: number): string => {
    const seconds = Math.floor(ms / 1000)
    const minutes = Math.floor(seconds / 60)
    if (minutes > 0) {
      return `${minutes}m ${seconds % 60}s`
    }
    return `${seconds}s`
  }

  return {
    // Session event handling
    event: async ({ event }) => {
      if (event.type === "session.created") {
        // Reset state for new session
        state.phase = "idle"
        state.currentBehavior = null
        state.lastTestResult = null
        state.sessionStats = {
          testsRun: 0,
          testsPass: 0,
          testsFail: 0,
          commits: 0,
          reverts: 0,
          behaviors: [],
          startTime: new Date(),
        }
        console.log("[tdd-workflow] Session started, TDD state reset")
      }

      if (event.type === "session.idle" && state.sessionStats.startTime) {
        // Report session metrics
        const duration = Date.now() - state.sessionStats.startTime.getTime()
        const stats = state.sessionStats
        console.log(`[tdd-workflow] Session metrics:
  Duration: ${formatDuration(duration)}
  Tests: ${stats.testsRun} run, ${stats.testsPass} pass, ${stats.testsFail} fail
  Git: ${stats.commits} commits, ${stats.reverts} reverts
  Behaviors: ${stats.behaviors.length} completed`)
      }
    },

    // Track tool execution
    "tool.execute.after": async (input, output) => {
      if (input.tool === "bash") {
        const command = (output as any).output as string || ""
        
        // Track test runs
        if (command.includes("gleam test") || command.includes("go test")) {
          state.sessionStats.testsRun++
          if (command.includes("FAILED") || command.includes("FAIL")) {
            state.sessionStats.testsFail++
            state.lastTestResult = "fail"
          } else if (command.includes("ok") || command.includes("Passed")) {
            state.sessionStats.testsPass++
            state.lastTestResult = "pass"
          }
        }

        // Track commits
        if (command.includes("git commit")) {
          state.sessionStats.commits++
          state.lastCommit = await getLastCommit()
        }

        // Track reverts
        if (command.includes("git reset --hard") || command.includes("git revert")) {
          state.sessionStats.reverts++
        }
      }
    },

    // TDD workflow tools
    tool: {
      // Enter TDD Red phase
      tdd_red: tool({
        description: "Enter TDD Red phase. Write a failing test for a behavior. Returns phase status and next steps.",
        args: {
          behavior: tool.schema.string(),
          testFile: tool.schema.string().optional(),
        },
        async execute(args) {
          state.phase = "red"
          state.currentBehavior = args.behavior

          return `🔴 TDD RED PHASE: ${args.behavior}

Current State:
  Phase: RED (write failing test)
  Behavior: ${args.behavior}
  ${args.testFile ? `Test file: ${args.testFile}` : ""}

Instructions:
1. Write ONE test that captures this behavior
2. Test must compile but FAIL
3. Run tests to confirm failure
4. Commit the failing test

Commands to run after writing test:
  go test ./... -run Test<BehaviorName>  # or: cd gleam && gleam test
  git add . && git commit -m "test: add failing test for ${args.behavior}"

When test is committed, use tdd_green to proceed.`
        },
      }),

      // Enter TDD Green phase  
      tdd_green: tool({
        description: "Enter TDD Green phase. Implement minimal code to make the test pass.",
        args: {},
        async execute() {
          if (state.phase !== "red") {
            return `⚠️ Cannot enter GREEN phase: not in RED phase. Current phase: ${state.phase}`
          }

          state.phase = "green"

          return `🟢 TDD GREEN PHASE: ${state.currentBehavior}

Current State:
  Phase: GREEN (make test pass)
  Behavior: ${state.currentBehavior}

Instructions:
1. Write MINIMAL code to make the test pass
2. Emphasis on minimal, not clever
3. Run tests after each change

TCR Discipline:
  IF tests pass → git add . && git commit -m "feat: ${state.currentBehavior}"
  IF tests fail → git reset --hard HEAD (try smaller step)

When tests pass and committed, use tdd_refactor to improve.`
        },
      }),

      // Enter TDD Refactor phase
      tdd_refactor: tool({
        description: "Enter TDD Refactor phase. Improve code quality without changing behavior.",
        args: {},
        async execute() {
          if (state.phase !== "green") {
            return `⚠️ Cannot enter REFACTOR phase: not in GREEN phase. Current phase: ${state.phase}`
          }

          state.phase = "refactor"

          return `🔵 TDD REFACTOR PHASE: ${state.currentBehavior}

Current State:
  Phase: REFACTOR (improve code)
  Behavior: ${state.currentBehavior}

Instructions:
1. Look for improvement opportunities
2. Run tests after EACH refactor step
3. If tests fail → REVERT immediately (TCR)

Improvement Areas:
  - Remove duplication
  - Improve names
  - Extract functions
  - Simplify logic

TCR Discipline:
  After each small refactor:
    go test ./...  # or: cd gleam && gleam test
    IF pass → git add . && git commit -m "refactor: <improvement>"
    IF fail → git reset --hard HEAD

When refactoring complete, use tdd_done to mark behavior complete.`
        },
      }),

      // Mark behavior complete
      tdd_done: tool({
        description: "Mark current TDD behavior as complete. Moves to idle state for next behavior.",
        args: {},
        async execute() {
          if (!state.currentBehavior) {
            return "⚠️ No behavior in progress"
          }

          const behavior = state.currentBehavior
          state.sessionStats.behaviors.push(behavior)
          state.phase = "idle"
          state.currentBehavior = null

          return `✅ TDD BEHAVIOR COMPLETE: ${behavior}

Session Progress:
  Behaviors completed: ${state.sessionStats.behaviors.length}
  - ${state.sessionStats.behaviors.join("\n  - ")}

Next:
  Use tdd_red to start the next behavior, or
  Use tdd_status to see current state`
        },
      }),

      // Get current TDD status
      tdd_status: tool({
        description: "Get current TDD workflow status including phase, behavior, and session metrics.",
        args: {},
        async execute() {
          const stats = state.sessionStats
          const duration = stats.startTime 
            ? formatDuration(Date.now() - stats.startTime.getTime())
            : "N/A"

          const phaseEmoji = {
            idle: "⚪",
            red: "🔴",
            green: "🟢",
            refactor: "🔵"
          }[state.phase]

          return `TDD Workflow Status

Current State:
  ${phaseEmoji} Phase: ${state.phase.toUpperCase()}
  Behavior: ${state.currentBehavior || "(none)"}
  Last Test: ${state.lastTestResult || "(none)"}
  Last Commit: ${state.lastCommit || "(none)"}

Session Metrics:
  Duration: ${duration}
  Tests Run: ${stats.testsRun}
  Tests Pass: ${stats.testsPass}
  Tests Fail: ${stats.testsFail}
  Commits: ${stats.commits}
  Reverts: ${stats.reverts}

Behaviors Completed: ${stats.behaviors.length}
${stats.behaviors.length > 0 ? "  - " + stats.behaviors.join("\n  - ") : ""}

Next Steps:
${state.phase === "idle" ? "  Use tdd_red to start a new behavior" : ""}
${state.phase === "red" ? "  Write failing test, then use tdd_green" : ""}
${state.phase === "green" ? "  Make test pass, then use tdd_refactor" : ""}
${state.phase === "refactor" ? "  Improve code, then use tdd_done" : ""}`
        },
      }),

      // Run tests and report
      tdd_test: tool({
        description: "Run tests and report results. Automatically detects Go or Gleam projects.",
        args: {
          pattern: tool.schema.string().optional(),
        },
        async execute(args) {
          state.sessionStats.testsRun++
          
          const { pass, output } = await runTests()
          
          if (pass) {
            state.sessionStats.testsPass++
            state.lastTestResult = "pass"
          } else {
            state.sessionStats.testsFail++
            state.lastTestResult = "fail"
          }

          const emoji = pass ? "✅" : "❌"
          const status = pass ? "PASS" : "FAIL"

          return `${emoji} Tests: ${status}

${output.slice(0, 2000)}${output.length > 2000 ? "\n... (truncated)" : ""}

TCR Guidance (Phase: ${state.phase}):
${pass && state.phase === "green" ? "  → Tests pass! Commit and proceed to refactor." : ""}
${pass && state.phase === "refactor" ? "  → Tests pass! Commit the refactor." : ""}
${!pass && state.phase === "red" ? "  → Tests fail as expected! Commit and proceed to green." : ""}
${!pass && state.phase === "green" ? "  → Tests fail. Try a smaller step or revert: git reset --hard HEAD" : ""}
${!pass && state.phase === "refactor" ? "  → Tests fail! REVERT immediately: git reset --hard HEAD" : ""}`
        },
      }),

      // TCR commit (if tests pass)
      tcr_commit: tool({
        description: "TCR-style commit: run tests first, only commit if they pass.",
        args: {
          message: tool.schema.string(),
        },
        async execute(args) {
          // Run tests first
          const { pass, output } = await runTests()
          
          if (!pass) {
            state.sessionStats.testsFail++
            state.lastTestResult = "fail"
            return `❌ TCR: Tests failed - NOT committing

${output.slice(0, 1000)}

TCR Discipline:
  - Fix the code, OR
  - Revert: git reset --hard HEAD`
          }

          // Tests pass - commit
          try {
            await $`git add .`.quiet()
            await $`git commit -m "${args.message}"`.quiet()
            state.sessionStats.commits++
            state.sessionStats.testsPass++
            state.lastTestResult = "pass"
            state.lastCommit = await getLastCommit()

            return `✅ TCR: Committed (${state.lastCommit})

Message: ${args.message}

Tests passed, changes committed.`
          } catch (e: any) {
            return `⚠️ TCR: Tests passed but commit failed: ${e.message}`
          }
        },
      }),

      // TCR revert
      tcr_revert: tool({
        description: "TCR-style revert: immediately revert to last commit.",
        args: {},
        async execute() {
          try {
            await $`git reset --hard HEAD`.quiet()
            state.sessionStats.reverts++

            return `⏪ TCR: Reverted to ${await getLastCommit()}

Working directory reset to last commit.
Try a smaller step next time.`
          } catch (e: any) {
            return `⚠️ TCR: Revert failed: ${e.message}`
          }
        },
      }),
    },
  }
}

export default TddWorkflowPlugin
