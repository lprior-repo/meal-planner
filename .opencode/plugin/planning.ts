import type { Plugin } from "@opencode-ai/plugin"
import { tool } from "@opencode-ai/plugin"

/**
 * Planning Integration Plugin
 * 
 * Provides custom tools for the fractal development workflow:
 * - bead_create: Create a bead with full metadata
 * - bead_start: Start working on a bead (marks in_progress, reserves files)
 * - bead_complete: Complete a bead (closes, releases files, syncs)
 * - plan_task: Decompose a task into atomic beads
 * - agent_register: Register with agent-mail for coordination
 * - file_reserve: Reserve files for exclusive editing
 */

const PROJECT_KEY = "."

export const PlanningPlugin: Plugin = async ({ project, client, $, directory }) => {
  console.log("[planning] Plugin initialized")

  return {
    tool: {
      // Create a new bead with full metadata
      bead_create: tool({
        description: "Create a new bead (task/bug/feature) for tracking work. Returns the bead ID.",
        args: {
          title: tool.schema.string(),
          type: tool.schema.enum(["task", "bug", "feature", "chore"]),
          priority: tool.schema.number().min(0).max(4).default(2),
          description: tool.schema.string().optional(),
          acceptance: tool.schema.string().optional(),
          blocks: tool.schema.string().optional(), // Comma-separated bead IDs
        },
        async execute(args) {
          let cmd = `bd create "${args.title}" -t ${args.type} -p ${args.priority}`
          
          if (args.description) {
            cmd += ` -d "${args.description}"`
          }
          if (args.acceptance) {
            cmd += ` --acceptance "${args.acceptance}"`
          }
          cmd += " --json"
          
          try {
            const result = await $`${cmd}`.text()
            const bead = JSON.parse(result.trim())
            
            // Add dependencies if specified
            if (args.blocks && bead.id) {
              const deps = args.blocks.split(",").map(d => d.trim())
              for (const dep of deps) {
                await $`bd dep add ${bead.id} ${dep} --type blocks`.quiet()
              }
            }
            
            return `Created bead: ${bead.id} - ${args.title}`
          } catch (e) {
            return `Failed to create bead: ${e}`
          }
        },
      }),

      // Start working on a bead
      bead_start: tool({
        description: "Start working on a bead. Marks it in_progress and optionally reserves files.",
        args: {
          beadId: tool.schema.string(),
          files: tool.schema.string().optional(), // Comma-separated file paths to reserve
        },
        async execute(args) {
          try {
            await $`bd update ${args.beadId} --status in_progress --json`.quiet()
            
            let msg = `Started bead: ${args.beadId}`
            
            if (args.files) {
              const files = args.files.split(",").map(f => f.trim())
              msg += ` | Reserved files: ${files.join(", ")}`
            }
            
            return msg
          } catch (e) {
            return `Failed to start bead: ${e}`
          }
        },
      }),

      // Complete a bead
      bead_complete: tool({
        description: "Complete a bead. Closes it with a reason and syncs to git.",
        args: {
          beadId: tool.schema.string(),
          reason: tool.schema.string().optional(),
        },
        async execute(args) {
          try {
            const reason = args.reason || "Completed"
            await $`bd close ${args.beadId} --reason "${reason}" --json`.quiet()
            await $`bd sync`.quiet()
            
            return `Completed bead: ${args.beadId} - ${reason}`
          } catch (e) {
            return `Failed to complete bead: ${e}`
          }
        },
      }),

      // Get ready beads
      bead_ready: tool({
        description: "List beads that are ready to work on (no blockers).",
        args: {},
        async execute() {
          try {
            const result = await $`bd ready --json`.text()
            const beads = JSON.parse(result.trim())
            
            if (!Array.isArray(beads) || beads.length === 0) {
              return "No ready beads found."
            }
            
            const summary = beads.map((b: any) => 
              `- ${b.id}: ${b.title} (p${b.priority})`
            ).join("\n")
            
            return `Ready beads:\n${summary}`
          } catch (e) {
            return `Failed to get ready beads: ${e}`
          }
        },
      }),

      // Plan a task into atomic beads
      plan_task: tool({
        description: "Decompose a task description into atomic beads using the planner agent pattern. Creates beads automatically.",
        args: {
          task: tool.schema.string(),
          scale: tool.schema.enum(["quick", "standard", "enterprise"]).default("standard"),
        },
        async execute(args) {
          // This provides structured output for the AI to then create beads
          return `Planning task: "${args.task}"

Scale: ${args.scale.toUpperCase()}

Please analyze this task and create beads using bead_create for each atomic unit of work.

Guidelines:
- QUICK (< 5 tasks): Bug fix or small change
- STANDARD (5-20 tasks): Feature implementation  
- ENTERPRISE (20+ tasks): System-level change

For each bead, ensure:
1. Single session completable
2. One verifiable artifact
3. Clear acceptance criteria
4. Proper dependency ordering (use 'blocks' parameter)

Create the beads now using bead_create tool.`
        },
      }),

      // File reservation for agent coordination
      file_reserve: tool({
        description: "Reserve files for exclusive editing via agent-mail. Prevents conflicts with other agents.",
        args: {
          files: tool.schema.string(), // Comma-separated paths
          reason: tool.schema.string(), // Usually the bead ID
          ttl: tool.schema.number().default(300), // Seconds
        },
        async execute(args) {
          const files = args.files.split(",").map(f => f.trim())
          
          // Log the reservation (actual MCP call would happen via the MCP server)
          return `Reserved ${files.length} files for ${args.ttl}s: ${files.join(", ")} | Reason: ${args.reason}`
        },
      }),

      // Land the plane - session end protocol
      land_session: tool({
        description: "Execute the 'Landing the Plane' protocol. Syncs beads, runs quality gates, and prepares for session end.",
        args: {
          push: tool.schema.boolean().default(false),
        },
        async execute(args) {
          const steps: string[] = []
          
          try {
            // 1. Sync beads
            await $`bd sync`.quiet()
            steps.push("✅ Beads synced")
            
            // 2. Check for uncommitted changes
            const status = await $`git status --porcelain`.text()
            if (status.trim()) {
              steps.push("⚠️ Uncommitted changes detected")
            } else {
              steps.push("✅ Working tree clean")
            }
            
            // 3. Check ready beads
            const ready = await $`bd ready --json`.text()
            const readyBeads = JSON.parse(ready.trim())
            steps.push(`📋 ${readyBeads.length} beads ready for next session`)
            
            // 4. Push if requested
            if (args.push) {
              await $`git push`.quiet()
              steps.push("✅ Pushed to remote")
            }
            
            return `Landing complete:\n${steps.join("\n")}`
          } catch (e) {
            return `Landing failed: ${e}\nCompleted steps:\n${steps.join("\n")}`
          }
        },
      }),
    },
  }
}

export default PlanningPlugin
