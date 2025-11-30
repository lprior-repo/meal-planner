import type { Plugin } from "@opencode-ai/plugin"
import { tool } from "@opencode-ai/plugin"

/**
 * Session Context Plugin
 * 
 * Enhances chat with session awareness and context injection:
 * - Tracks session history and patterns
 * - Injects relevant context from beads
 * - Provides session summary tools
 * - Handles chat.message hook for context enhancement
 * 
 * Hooks:
 * - session.created: Initialize session context
 * - session.idle: Save session summary
 * - chat.message: Inject relevant context
 */

interface SessionContext {
  id: string | null
  startTime: Date | null
  messageCount: number
  toolsUsed: Map<string, number>
  filesEdited: Set<string>
  beadIds: Set<string>
  lastActivity: Date | null
  keyDecisions: string[]
}

const context: SessionContext = {
  id: null,
  startTime: null,
  messageCount: 0,
  toolsUsed: new Map(),
  filesEdited: new Set(),
  beadIds: new Set(),
  lastActivity: null,
  keyDecisions: [],
}

export const SessionContextPlugin: Plugin = async ({ project, client, $, directory }) => {
  console.log("[session-context] Plugin initialized")

  // Helper: Get current beads context
  const getBeadsContext = async (): Promise<string> => {
    try {
      const result = await $`bd ready --json`.text()
      const beads = JSON.parse(result.trim())
      
      if (!Array.isArray(beads) || beads.length === 0) {
        return "No ready beads."
      }

      return beads.slice(0, 5).map((b: any) => 
        `- ${b.id}: ${b.title} (p${b.priority})`
      ).join("\n")
    } catch {
      return "Unable to fetch beads."
    }
  }

  // Helper: Get git context
  const getGitContext = async (): Promise<string> => {
    try {
      const branch = (await $`git branch --show-current`.text()).trim()
      const status = (await $`git status --porcelain`.text()).trim()
      const lastCommit = (await $`git log --oneline -1`.text()).trim()

      let ctx = `Branch: ${branch}\n`
      ctx += `Last commit: ${lastCommit}\n`
      
      if (status) {
        const lines = status.split("\n")
        ctx += `Changes: ${lines.length} files\n`
        if (lines.length <= 5) {
          ctx += status + "\n"
        }
      } else {
        ctx += "Working tree: clean\n"
      }

      return ctx
    } catch {
      return "Git context unavailable."
    }
  }

  // Helper: Format duration
  const formatDuration = (ms: number): string => {
    const seconds = Math.floor(ms / 1000)
    const minutes = Math.floor(seconds / 60)
    const hours = Math.floor(minutes / 60)
    
    if (hours > 0) return `${hours}h ${minutes % 60}m`
    if (minutes > 0) return `${minutes}m ${seconds % 60}s`
    return `${seconds}s`
  }

  return {
    // Event handling
    event: async ({ event }) => {
      if (event.type === "session.created") {
        context.id = (event as any).properties?.sessionID || null
        context.startTime = new Date()
        context.messageCount = 0
        context.toolsUsed = new Map()
        context.filesEdited = new Set()
        context.beadIds = new Set()
        context.lastActivity = new Date()
        context.keyDecisions = []
        
        console.log(`[session-context] Session started: ${context.id}`)
      }

      if (event.type === "session.idle" && context.startTime) {
        const duration = Date.now() - context.startTime.getTime()
        console.log(`[session-context] Session idle after ${formatDuration(duration)}
  Messages: ${context.messageCount}
  Tools used: ${Array.from(context.toolsUsed.entries()).map(([k, v]) => `${k}:${v}`).join(", ")}
  Files edited: ${context.filesEdited.size}`)
      }
    },

    // Track tool usage
    "tool.execute.after": async (input, output) => {
      const tool = input.tool
      context.toolsUsed.set(tool, (context.toolsUsed.get(tool) || 0) + 1)
      context.lastActivity = new Date()

      // Track file edits
      if (tool === "edit" || tool === "write") {
        const filePath = (output as any).metadata?.filePath
        if (filePath) {
          context.filesEdited.add(filePath)
        }
      }

      // Track bead operations
      if (tool === "bash") {
        const cmd = (output as any).output || ""
        const beadMatch = cmd.match(/bd-[a-z0-9-]+/g)
        if (beadMatch) {
          beadMatch.forEach((id: string) => context.beadIds.add(id))
        }
      }
    },

    // Chat message hook for context injection
    "chat.message": async (input, output) => {
      context.messageCount++
      context.lastActivity = new Date()
      
      // Could enhance the message with context here
      // For now, just track it
    },

    tool: {
      // Get current session context
      session_context: tool({
        description: "Get rich context about the current session including time, activity, beads, and git state.",
        args: {},
        async execute() {
          const duration = context.startTime 
            ? formatDuration(Date.now() - context.startTime.getTime())
            : "N/A"

          const beadsCtx = await getBeadsContext()
          const gitCtx = await getGitContext()

          let output = `=== Session Context ===

Session:
  ID: ${context.id || "(unknown)"}
  Duration: ${duration}
  Messages: ${context.messageCount}
  Last activity: ${context.lastActivity?.toISOString() || "N/A"}

Tool Usage:`

          if (context.toolsUsed.size > 0) {
            for (const [tool, count] of context.toolsUsed.entries()) {
              output += `\n  ${tool}: ${count}`
            }
          } else {
            output += "\n  (none yet)"
          }

          output += `

Files Edited: ${context.filesEdited.size}`
          if (context.filesEdited.size > 0 && context.filesEdited.size <= 10) {
            for (const file of context.filesEdited) {
              output += `\n  ${file}`
            }
          }

          output += `

Beads Touched: ${context.beadIds.size}`
          if (context.beadIds.size > 0) {
            for (const id of context.beadIds) {
              output += `\n  ${id}`
            }
          }

          output += `

Git State:
${gitCtx}

Ready Beads:
${beadsCtx}`

          if (context.keyDecisions.length > 0) {
            output += `

Key Decisions:`
            for (const decision of context.keyDecisions) {
              output += `\n  - ${decision}`
            }
          }

          return output
        },
      }),

      // Record a key decision
      session_decision: tool({
        description: "Record a key decision made during this session for future reference.",
        args: {
          decision: tool.schema.string(),
          reasoning: tool.schema.string().optional(),
        },
        async execute(args) {
          const entry = args.reasoning 
            ? `${args.decision} (${args.reasoning})`
            : args.decision
          
          context.keyDecisions.push(entry)

          return `📝 Recorded decision: ${args.decision}

Total decisions this session: ${context.keyDecisions.length}

Decisions:
${context.keyDecisions.map((d, i) => `  ${i + 1}. ${d}`).join("\n")}`
        },
      }),

      // Get session summary for handoff
      session_summary: tool({
        description: "Generate a comprehensive session summary for handoff or documentation.",
        args: {},
        async execute() {
          const duration = context.startTime 
            ? formatDuration(Date.now() - context.startTime.getTime())
            : "N/A"

          const gitCtx = await getGitContext()
          const beadsCtx = await getBeadsContext()

          let summary = `# Session Summary

## Overview
- Duration: ${duration}
- Messages exchanged: ${context.messageCount}
- Files edited: ${context.filesEdited.size}
- Beads touched: ${context.beadIds.size}

## Files Modified`

          if (context.filesEdited.size > 0) {
            for (const file of context.filesEdited) {
              summary += `\n- ${file}`
            }
          } else {
            summary += "\n(none)"
          }

          summary += `

## Tool Usage`
          for (const [tool, count] of context.toolsUsed.entries()) {
            summary += `\n- ${tool}: ${count} calls`
          }

          if (context.keyDecisions.length > 0) {
            summary += `

## Key Decisions`
            for (const decision of context.keyDecisions) {
              summary += `\n- ${decision}`
            }
          }

          summary += `

## Git State
\`\`\`
${gitCtx}
\`\`\`

## Ready Work
${beadsCtx}

## Handoff Notes
Add any additional notes for the next session here.`

          return summary
        },
      }),

      // Quick status
      session_status: tool({
        description: "Quick session status: duration and activity counts.",
        args: {},
        async execute() {
          const duration = context.startTime 
            ? formatDuration(Date.now() - context.startTime.getTime())
            : "N/A"

          return `Session: ${duration} | ${context.messageCount} msgs | ${context.filesEdited.size} files | ${context.beadIds.size} beads`
        },
      }),
    },
  }
}

export default SessionContextPlugin
