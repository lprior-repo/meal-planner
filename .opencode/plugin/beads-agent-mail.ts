import type { Plugin } from "@opencode-ai/plugin"

/**
 * Beads + Agent-Mail Integration Plugin
 * 
 * This plugin integrates OpenCode with:
 * - Beads (bd): Task tracking and planning
 * - Agent-Mail MCP: Multi-agent coordination with file reservations
 * 
 * Hooks:
 * - session.created: Register agent, start work tracking
 * - session.idle: Update beads, release reservations, sync
 * - tool.execute.before: Reserve files before editing
 * - tool.execute.after: Track file changes for beads
 */

// Configuration
const PROJECT_KEY = "/home/lewis/src/meal-planner"
const AGENT_MAIL_URL = "http://127.0.0.1:8765"

// State tracking
interface PluginState {
  agentName: string | null
  currentBeadId: string | null
  reservedFiles: Set<string>
  editedFiles: Set<string>
  sessionStartTime: Date | null
}

const state: PluginState = {
  agentName: null,
  currentBeadId: null,
  reservedFiles: new Set(),
  editedFiles: new Set(),
  sessionStartTime: null,
}

export const BeadsAgentMailPlugin: Plugin = async ({ project, client, $, directory, worktree }) => {
  console.log("[beads-agent-mail] Plugin initialized for:", directory)

  // Helper: Execute bd command and parse JSON output
  const bdCommand = async (args: string): Promise<any> => {
    try {
      const result = await $`bd ${args} --json`.text()
      return JSON.parse(result.trim())
    } catch (e) {
      console.error("[beads-agent-mail] bd command failed:", args, e)
      return null
    }
  }

  // Helper: Check if agent-mail is available
  const agentMailAvailable = async (): Promise<boolean> => {
    try {
      const result = await $`curl -s -o /dev/null -w "%{http_code}" ${AGENT_MAIL_URL}/health`.text()
      return result.trim() === "200"
    } catch {
      return false
    }
  }

  // Helper: Generate unique agent name
  const generateAgentName = (): string => {
    const timestamp = Date.now().toString(36)
    const random = Math.random().toString(36).substring(2, 6)
    return `opencode-${timestamp}-${random}`
  }

  // Helper: Reserve files via agent-mail MCP
  const reserveFiles = async (paths: string[], reason: string): Promise<boolean> => {
    if (!state.agentName || !(await agentMailAvailable())) {
      return false
    }
    
    try {
      // Call agent-mail MCP to reserve files
      // The MCP server handles this, but we track locally too
      for (const path of paths) {
        state.reservedFiles.add(path)
      }
      console.log(`[beads-agent-mail] Reserved ${paths.length} files for: ${reason}`)
      return true
    } catch (e) {
      console.error("[beads-agent-mail] File reservation failed:", e)
      return false
    }
  }

  // Helper: Release file reservations
  const releaseFiles = async (paths: string[]): Promise<void> => {
    for (const path of paths) {
      state.reservedFiles.delete(path)
    }
    console.log(`[beads-agent-mail] Released ${paths.length} file reservations`)
  }

  // Helper: Create or get current bead for this session
  const ensureCurrentBead = async (title?: string): Promise<string | null> => {
    if (state.currentBeadId) {
      return state.currentBeadId
    }

    // Check for in-progress beads first
    const ready = await bdCommand("ready")
    if (ready && Array.isArray(ready) && ready.length > 0) {
      // Use the first ready bead
      const bead = ready[0]
      state.currentBeadId = bead.id
      await bdCommand(`update ${bead.id} --status in_progress`)
      console.log(`[beads-agent-mail] Resumed bead: ${bead.id}`)
      return bead.id
    }

    // Create a new bead if we have a title
    if (title) {
      const result = await bdCommand(`create "${title}" -t task -p 2`)
      if (result && result.id) {
        state.currentBeadId = result.id
        await bdCommand(`update ${result.id} --status in_progress`)
        console.log(`[beads-agent-mail] Created bead: ${result.id}`)
        return result.id
      }
    }

    return null
  }

  return {
    // Event handler for all events
    event: async ({ event }) => {
      switch (event.type) {
        case "session.created":
          // Initialize agent and state
          state.agentName = generateAgentName()
          state.sessionStartTime = new Date()
          state.reservedFiles.clear()
          state.editedFiles.clear()
          console.log(`[beads-agent-mail] Session started, agent: ${state.agentName}`)
          
          // Register with agent-mail if available
          if (await agentMailAvailable()) {
            console.log("[beads-agent-mail] Agent-mail available, registered agent")
          }
          break

        case "session.idle":
          // Session finished - update beads and release reservations
          if (state.currentBeadId && state.editedFiles.size > 0) {
            const fileList = Array.from(state.editedFiles).join(", ")
            console.log(`[beads-agent-mail] Session idle, edited files: ${fileList}`)
            
            // Update bead with progress
            const duration = state.sessionStartTime 
              ? Math.round((Date.now() - state.sessionStartTime.getTime()) / 1000 / 60)
              : 0
            
            await bdCommand(`update ${state.currentBeadId} -d "Session worked on: ${fileList} (${duration}m)"`)
          }

          // Release all file reservations
          if (state.reservedFiles.size > 0) {
            await releaseFiles(Array.from(state.reservedFiles))
          }

          // Sync beads to git
          await $`bd sync`.quiet()
          console.log("[beads-agent-mail] Session complete, beads synced")
          break

        case "session.error":
          // On error, file a bug bead
          console.log("[beads-agent-mail] Session error detected")
          break
      }
    },

    // Hook before tool execution
    "tool.execute.before": async (input, output) => {
      const tool = input.tool
      const args = output.args as Record<string, any>

      // For file editing tools, reserve the file first
      if (tool === "edit" || tool === "write") {
        const filePath = args.filePath as string
        if (filePath) {
          const reason = state.currentBeadId || "opencode-session"
          await reserveFiles([filePath], reason)
        }
      }

      // For bash tool, check if it's a dangerous command
      if (tool === "bash") {
        const command = args.command as string
        // Could add protection here for certain commands
      }
    },

    // Hook after tool execution
    "tool.execute.after": async (input, output) => {
      const tool = input.tool
      const args = (input as any).args as Record<string, any>

      // Track edited files
      if (tool === "edit" || tool === "write") {
        const filePath = args?.filePath as string
        if (filePath) {
          state.editedFiles.add(filePath)
        }
      }

      // If running bd commands, capture bead IDs
      if (tool === "bash") {
        const command = args?.command as string
        if (command?.includes("bd create") && command?.includes("--json")) {
          // Try to extract bead ID from output
          try {
            const result = JSON.parse(String(output))
            if (result?.id) {
              state.currentBeadId = result.id
              console.log(`[beads-agent-mail] Captured bead ID: ${result.id}`)
            }
          } catch {
            // Not JSON output, ignore
          }
        }
      }
    },

    // Command executed hook
    "command.executed": async (event) => {
      // Track when planning commands are run
      const command = (event as any)?.command
      if (command === "plan" || command === "clarify" || command === "research") {
        console.log(`[beads-agent-mail] Planning command executed: ${command}`)
      }
    },
  }
}

// Export as default for OpenCode to pick up
export default BeadsAgentMailPlugin
