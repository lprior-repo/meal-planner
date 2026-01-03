#!/usr/bin/env node

import { createOpencode } from "@opencode-ai/sdk/v2"
import { readFileSync } from "fs"
import { resolve } from "path"

// Parse CLI arguments
const args = process.argv.slice(2)
let promptFile = "prompt.md"
let directory = process.cwd()
let maxLoops = 0
let verbose = true // Default to verbose

for (let i = 0; i < args.length; i++) {
  switch (args[i]) {
    case "-prompt":
    case "--prompt":
      promptFile = args[++i]
      break
    case "-dir":
    case "--dir":
      directory = resolve(args[++i])
      break
    case "-max":
    case "--max":
      maxLoops = parseInt(args[++i], 10)
      break
    case "-q":
    case "--quiet":
      verbose = false
      break
    case "-h":
    case "--help":
      console.log(`Usage: ralph [options]
Options:
  --prompt, -prompt <file>  Prompt file (default: prompt.md)
  --dir, -dir <path>        Working directory (default: current)
  --max, -max <n>           Max loops, 0=unlimited (default: 0)
  -q, --quiet               Quiet mode (no streaming output)
  -h, --help                Show this help`)
      process.exit(0)
  }
}

// Read prompt file
let prompt
try {
  prompt = readFileSync(promptFile, "utf-8")
} catch (err) {
  console.error(`Error: Cannot read prompt file: ${promptFile}`)
  process.exit(1)
}

console.log(`Ralph - Autonomous Development Loop`)
console.log(`===================================`)
console.log(`Prompt: ${promptFile}`)
console.log(`Directory: ${directory}`)
console.log(`Max loops: ${maxLoops || "unlimited"}`)
console.log()

// Create opencode instance (starts server + client)
console.log("Starting opencode server...")
const port = 4096 + Math.floor(Math.random() * 1000)
const { client, server } = await createOpencode({
  cwd: directory,
  port: port,
})
console.log(`Server: ${server.url}`)

// Handle Ctrl+C
let shuttingDown = false
process.on("SIGINT", async () => {
  if (shuttingDown) return
  shuttingDown = true
  console.log("\n\nShutting down...")
  server.close()
  process.exit(0)
})

// Create session
console.log("Creating session...")
const sessionResult = await client.session.create({ title: "ralph-session" })
const sessionId = sessionResult.data.id
console.log(`Session: ${sessionId}`)
console.log()

// Subscribe to events for real-time output
const { stream: eventStream } = await client.event.subscribe()

// Handle events in background
;(async () => {
  try {
    for await (const event of eventStream) {
      if (shuttingDown) break
      
      const props = event.properties
      
      // Filter to our session
      if (props?.sessionID && props.sessionID !== sessionId) continue
      if (props?.part?.sessionID && props.part.sessionID !== sessionId) continue

      if (event.type === "message.part.updated") {
        const part = props.part
        if (!part) continue
        
        // Show text as it streams
        if (part.type === "text") {
          if (verbose && props.delta) {
            process.stdout.write(props.delta)
          }
        }
        
        // Show tool completions
        if (part.type === "tool" && part.state?.status === "completed") {
          const tool = part.tool || "unknown"
          const title = part.state.title || JSON.stringify(part.state.input || {})
          console.log(`\n[${tool}] ${title}`)
          
          // Show bash output
          if (tool === "bash" && part.state.output?.trim()) {
            console.log(part.state.output)
          }
        }
      } else if (event.type === "message.part.created") {
        const newPart = props.part
        if (newPart?.type === "tool") {
          console.log(`\n[${newPart.tool}] Starting...`)
        }
      } else if (event.type === "permission.updated") {
        console.log(`\n[Permission] Auto-approving: ${props.title || props.id}`)
        try {
          await client.permission.respond({
            sessionID: sessionId,
            permissionID: props.id,
            response: "always",
          })
        } catch (e) {
          console.error(`Failed to approve: ${e.message}`)
        }
      } else if (event.type === "session.error") {
        if (props.error) {
          console.error(`\n[Error] ${props.error.name || props.error}`)
        }
      }
    }
  } catch (e) {
    if (!shuttingDown) {
      console.error(`Event stream error: ${e.message}`)
    }
  }
})()

// Main loop
let iteration = 0
while (!shuttingDown) {
  // Check max loops
  if (maxLoops > 0 && iteration >= maxLoops) {
    console.log(`\n\nReached max loops (${maxLoops}), exiting`)
    break
  }

  iteration++
  console.log(`\n========== Iteration ${iteration} ==========\n`)

  try {
    // Send prompt and wait for response
    await client.session.prompt({
      sessionID: sessionId,
      model: { providerID: "opencode", modelID: "minimax-m2.1-free" },
      parts: [{ type: "text", text: prompt }],
    })

    console.log(`\n---------- Iteration ${iteration} complete ----------`)
  } catch (err) {
    console.error(`\n[Error] ${err.message}`)
    if (err.message.includes("aborted") || err.message.includes("cancel")) {
      break
    }
    // Continue on other errors
  }
}

// Cleanup
console.log("\nStopping server...")
server.close()
console.log("Done")
