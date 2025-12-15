import type { Plugin } from "@opencode-ai/plugin"
import { tool } from "@opencode-ai/plugin"

/**
 * Quality Gates Plugin
 * 
 * Provides multi-layer quality validation for the fractal development workflow:
 * - Layer 1: Format & basic lint (fast)
 * - Layer 2: Full test suite
 * - Layer 3: Build verification
 * - Layer 4: Architecture checks
 * 
 * Hooks:
 * - session.idle: Run quick quality check before session ends
 * - tool.execute.after: Track quality metrics
 */

interface QualityResult {
  layer: string
  status: "pass" | "fail" | "skip"
  duration: number
  output: string
  issues: string[]
}

interface QualityState {
  lastRun: Date | null
  results: QualityResult[]
  totalIssues: number
}

const state: QualityState = {
  lastRun: null,
  results: [],
  totalIssues: 0,
}

export const QualityGatesPlugin: Plugin = async ({ project, client, $, directory }) => {
  console.log("[quality-gates] Plugin initialized")

  // Helper: Detect project type
  const detectProject = async (): Promise<"gleam" | "go" | "both" | "unknown"> => {
    const hasGleam = await $`test -f gleam/gleam.toml && echo "yes"`.text().catch(() => "")
    const hasGo = await $`test -f go.mod && echo "yes"`.text().catch(() => "")
    
    if (hasGleam.includes("yes") && hasGo.includes("yes")) return "both"
    if (hasGleam.includes("yes")) return "gleam"
    if (hasGo.includes("yes")) return "go"
    return "unknown"
  }

  // Layer 1: Format & Lint
  const runFormatLint = async (projectType: string): Promise<QualityResult> => {
    const start = Date.now()
    const issues: string[] = []
    let output = ""

    try {
      if (projectType === "go" || projectType === "both") {
        // Check Go formatting
        const fmtResult = await $`gofmt -l . 2>&1`.text().catch((e) => e.message)
        if (fmtResult.trim()) {
          issues.push(`Go files need formatting: ${fmtResult.trim().split("\n").length} files`)
          output += `Go format issues:\n${fmtResult}\n`
        }

        // Run golangci-lint if available
        const lintResult = await $`which golangci-lint && golangci-lint run --fast 2>&1`.text().catch(() => "")
        if (lintResult.includes("error") || lintResult.includes("warning")) {
          const errorCount = (lintResult.match(/error|warning/g) || []).length
          issues.push(`Go lint: ${errorCount} issues`)
          output += `Go lint:\n${lintResult.slice(0, 1000)}\n`
        }
      }

      if (projectType === "gleam" || projectType === "both") {
        // Gleam format check
        const fmtResult = await $`cd gleam && gleam format --check . 2>&1`.text().catch((e) => e.message)
        if (fmtResult.includes("would reformat")) {
          issues.push("Gleam files need formatting")
          output += `Gleam format issues:\n${fmtResult}\n`
        }
      }

      return {
        layer: "format-lint",
        status: issues.length === 0 ? "pass" : "fail",
        duration: Date.now() - start,
        output,
        issues,
      }
    } catch (e: any) {
      return {
        layer: "format-lint",
        status: "fail",
        duration: Date.now() - start,
        output: e.message,
        issues: ["Format/lint check failed"],
      }
    }
  }

  // Layer 2: Tests
  const runTests = async (projectType: string): Promise<QualityResult> => {
    const start = Date.now()
    const issues: string[] = []
    let output = ""

    try {
      if (projectType === "go" || projectType === "both") {
        const testResult = await $`go test ./... 2>&1`.text().catch((e) => e.message)
        output += `Go tests:\n${testResult}\n`
        
        if (testResult.includes("FAIL") || testResult.includes("error")) {
          const failMatch = testResult.match(/FAIL\s+(\S+)/g)
          issues.push(`Go tests failed: ${failMatch?.length || 1} packages`)
        }
      }

      if (projectType === "gleam" || projectType === "both") {
        const testResult = await $`cd gleam && gleam test 2>&1`.text().catch((e) => e.message)
        output += `Gleam tests:\n${testResult}\n`
        
        if (testResult.includes("FAILED") || testResult.includes("error:")) {
          issues.push("Gleam tests failed")
        }
      }

      return {
        layer: "tests",
        status: issues.length === 0 ? "pass" : "fail",
        duration: Date.now() - start,
        output,
        issues,
      }
    } catch (e: any) {
      return {
        layer: "tests",
        status: "fail",
        duration: Date.now() - start,
        output: e.message,
        issues: ["Test execution failed"],
      }
    }
  }

  // Layer 3: Build
  const runBuild = async (projectType: string): Promise<QualityResult> => {
    const start = Date.now()
    const issues: string[] = []
    let output = ""

    try {
      if (projectType === "go" || projectType === "both") {
        const buildResult = await $`go build ./... 2>&1`.text().catch((e) => e.message)
        output += `Go build:\n${buildResult || "Success"}\n`
        
        if (buildResult.includes("error")) {
          issues.push("Go build failed")
        }
      }

      if (projectType === "gleam" || projectType === "both") {
        const buildResult = await $`cd gleam && gleam build 2>&1`.text().catch((e) => e.message)
        output += `Gleam build:\n${buildResult}\n`
        
        if (buildResult.includes("error:")) {
          issues.push("Gleam build failed")
        }
      }

      return {
        layer: "build",
        status: issues.length === 0 ? "pass" : "fail",
        duration: Date.now() - start,
        output,
        issues,
      }
    } catch (e: any) {
      return {
        layer: "build",
        status: "fail",
        duration: Date.now() - start,
        output: e.message,
        issues: ["Build failed"],
      }
    }
  }

  // Layer 4: Type checking
  const runTypeCheck = async (projectType: string): Promise<QualityResult> => {
    const start = Date.now()
    const issues: string[] = []
    let output = ""

    try {
      if (projectType === "go" || projectType === "both") {
        const vetResult = await $`go vet ./... 2>&1`.text().catch((e) => e.message)
        output += `Go vet:\n${vetResult || "No issues"}\n`
        
        if (vetResult.trim() && !vetResult.includes("no issues")) {
          issues.push("Go vet found issues")
        }
      }

      if (projectType === "gleam" || projectType === "both") {
        const checkResult = await $`cd gleam && gleam check 2>&1`.text().catch((e) => e.message)
        output += `Gleam check:\n${checkResult}\n`
        
        if (checkResult.includes("error:")) {
          issues.push("Gleam type check failed")
        }
      }

      return {
        layer: "type-check",
        status: issues.length === 0 ? "pass" : "fail",
        duration: Date.now() - start,
        output,
        issues,
      }
    } catch (e: any) {
      return {
        layer: "type-check",
        status: "fail",
        duration: Date.now() - start,
        output: e.message,
        issues: ["Type check failed"],
      }
    }
  }

  return {
    // Optional: Quick check on session idle
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        // Could trigger a quick quality check here
        console.log("[quality-gates] Session idle - quality gates available via tools")
      }
    },

    tool: {
      // Quick quality check (fast)
      quality_quick: tool({
        description: "Run quick quality checks: format and type checking only. Fast feedback.",
        args: {},
        async execute() {
          const projectType = await detectProject()
          if (projectType === "unknown") {
            return "⚠️ Could not detect project type (no go.mod or gleam.toml found)"
          }

          const results: QualityResult[] = []
          
          // Layer 1: Format/Lint
          results.push(await runFormatLint(projectType))
          
          // Layer 4: Type check (fast)
          results.push(await runTypeCheck(projectType))

          state.lastRun = new Date()
          state.results = results
          state.totalIssues = results.reduce((sum, r) => sum + r.issues.length, 0)

          const allPass = results.every(r => r.status === "pass")
          const emoji = allPass ? "✅" : "❌"
          const totalDuration = results.reduce((sum, r) => sum + r.duration, 0)

          let output = `${emoji} Quality Quick Check (${totalDuration}ms)\n\n`

          for (const result of results) {
            const statusEmoji = result.status === "pass" ? "✅" : "❌"
            output += `${statusEmoji} ${result.layer}: ${result.status.toUpperCase()} (${result.duration}ms)\n`
            if (result.issues.length > 0) {
              output += `   Issues: ${result.issues.join(", ")}\n`
            }
          }

          if (!allPass) {
            output += `\n⚠️ Fix issues before proceeding.`
          }

          return output
        },
      }),

      // Full quality gate run
      quality_full: tool({
        description: "Run full quality gates: format, lint, tests, build, and type checks. Use before landing.",
        args: {
          verbose: tool.schema.boolean().default(false),
        },
        async execute(args) {
          const projectType = await detectProject()
          if (projectType === "unknown") {
            return "⚠️ Could not detect project type (no go.mod or gleam.toml found)"
          }

          const results: QualityResult[] = []

          // Layer 1: Format/Lint
          results.push(await runFormatLint(projectType))
          
          // Layer 2: Tests
          results.push(await runTests(projectType))
          
          // Layer 3: Build
          results.push(await runBuild(projectType))
          
          // Layer 4: Type check
          results.push(await runTypeCheck(projectType))

          state.lastRun = new Date()
          state.results = results
          state.totalIssues = results.reduce((sum, r) => sum + r.issues.length, 0)

          const allPass = results.every(r => r.status === "pass")
          const emoji = allPass ? "✅" : "❌"
          const totalDuration = results.reduce((sum, r) => sum + r.duration, 0)

          let output = `${emoji} Full Quality Gates (${totalDuration}ms)\n\n`

          output += `Project: ${projectType}\n\n`

          for (const result of results) {
            const statusEmoji = result.status === "pass" ? "✅" : "❌"
            output += `${statusEmoji} Layer: ${result.layer} - ${result.status.toUpperCase()} (${result.duration}ms)\n`
            
            if (result.issues.length > 0) {
              for (const issue of result.issues) {
                output += `   ⚠️ ${issue}\n`
              }
            }

            if (args.verbose && result.output) {
              output += `   Output:\n${result.output.slice(0, 500)}\n`
            }
          }

          output += `\n---\nTotal Issues: ${state.totalIssues}\n`

          if (!allPass) {
            output += `\n❌ Quality gates failed. Fix issues before landing.`
            
            // Suggest creating beads for issues
            output += `\n\nSuggested follow-up:
  bd create "Fix quality gate issues" -t bug -p 1 --json`
          } else {
            output += `\n✅ All quality gates passed. Safe to land.`
          }

          return output
        },
      }),

      // Get last quality run status
      quality_status: tool({
        description: "Get the status of the last quality gate run.",
        args: {},
        async execute() {
          if (!state.lastRun) {
            return "No quality gate run recorded. Use quality_quick or quality_full to run."
          }

          const allPass = state.results.every(r => r.status === "pass")
          const emoji = allPass ? "✅" : "❌"

          let output = `${emoji} Last Quality Run: ${state.lastRun.toISOString()}\n\n`

          for (const result of state.results) {
            const statusEmoji = result.status === "pass" ? "✅" : "❌"
            output += `${statusEmoji} ${result.layer}: ${result.status.toUpperCase()}\n`
            if (result.issues.length > 0) {
              output += `   Issues: ${result.issues.join(", ")}\n`
            }
          }

          output += `\nTotal Issues: ${state.totalIssues}`

          return output
        },
      }),

      // Run specific layer
      quality_layer: tool({
        description: "Run a specific quality layer: format-lint, tests, build, or type-check.",
        args: {
          layer: tool.schema.enum(["format-lint", "tests", "build", "type-check"]),
        },
        async execute(args) {
          const projectType = await detectProject()
          if (projectType === "unknown") {
            return "⚠️ Could not detect project type"
          }

          let result: QualityResult

          switch (args.layer) {
            case "format-lint":
              result = await runFormatLint(projectType)
              break
            case "tests":
              result = await runTests(projectType)
              break
            case "build":
              result = await runBuild(projectType)
              break
            case "type-check":
              result = await runTypeCheck(projectType)
              break
          }

          const emoji = result.status === "pass" ? "✅" : "❌"
          let output = `${emoji} ${result.layer}: ${result.status.toUpperCase()} (${result.duration}ms)\n\n`

          if (result.issues.length > 0) {
            output += "Issues:\n"
            for (const issue of result.issues) {
              output += `  ⚠️ ${issue}\n`
            }
            output += "\n"
          }

          output += `Output:\n${result.output.slice(0, 2000)}`

          return output
        },
      }),

      // Fix formatting
      quality_fix_format: tool({
        description: "Auto-fix formatting issues in Go and Gleam files.",
        args: {},
        async execute() {
          const projectType = await detectProject()
          let output = "Fixing formatting...\n\n"

          try {
            if (projectType === "go" || projectType === "both") {
              await $`gofmt -w .`.quiet()
              output += "✅ Go files formatted\n"
            }

            if (projectType === "gleam" || projectType === "both") {
              await $`cd gleam && gleam format .`.quiet()
              output += "✅ Gleam files formatted\n"
            }

            output += "\nRun quality_quick to verify."
            return output
          } catch (e: any) {
            return `❌ Formatting failed: ${e.message}`
          }
        },
      }),
    },
  }
}

export default QualityGatesPlugin
