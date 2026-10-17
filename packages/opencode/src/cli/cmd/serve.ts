import { Server } from "../../server/server"
import { Flag } from "../../flag/flag"
import { resolveNetworkOptions } from "../network"
import { cmd } from "./cmd"

process.env.OPENCODE_EXPERIMENTAL_HTTPAPI = "true"

async function startOpenWebUI(): Promise<void> {
  const { exec } = await import("child_process")
  
  return new Promise((resolve, reject) => {
    exec("docker ps --filter name=openwebui -q", (err, stdout) => {
      if (err) {
        console.log("Starting OpenWebUI container...")
        exec(
          "docker run -d --name openwebui -p 3000:8080 -e OLLAMA_BASE_URL=http://host.docker.internal:11435 -e API_KEY=opensearch-local openwebui/open-webui:latest",
          (e) => {
            if (e) {
              console.error("Failed to start OpenWebUI:", e.message)
              resolve()
            } else {
              console.log("OpenWebUI started at http://localhost:3000")
              setTimeout(resolve, 3000)
            }
          },
        )
        return
      }
      
      if (stdout.trim()) {
        console.log("OpenWebUI already running at http://localhost:3000")
        resolve()
        return
      }
      
      console.log("Starting OpenWebUI container...")
      exec(
        "docker run -d --name openwebui -p 3000:8080 -e OLLAMA_BASE_URL=http://host.docker.internal:11435 -e API_KEY=opensearch-local openwebui/open-webui:latest",
        (e) => {
          if (e) {
            console.error("Failed to start OpenWebUI:", e.message)
            resolve()
          } else {
            console.log("OpenWebUI started at http://localhost:3000")
            setTimeout(resolve, 3000)
          }
        },
      )
    })
  })
}

export const ServeCommand = cmd({
  command: "serve",
  builder: (yargs) =>
    yargs
      .option("api-only", {
        describe: "Start API server only (no TUI)",
        type: "boolean",
        default: false,
      })
      .option("no-webui", {
        describe: "Don't start OpenWebUI",
        type: "boolean",
        default: false,
      })
      .option("port", {
        describe: "Port for API server",
        type: "number",
        default: 11435,
      }),
  describe: "starts a headless opencode server with OpenAI-compatible API",
  handler: async (args) => {
    const port = args.port ?? 11435
    const apiOnly = args["api-only"] ?? false
    const noWebUI = args["no-webui"] ?? false
    
    if (!Flag.OPENCODE_SERVER_PASSWORD) {
      console.log("Warning: OPENCODE_SERVER_PASSWORD is not set; server is unsecured.")
    }
    
    console.log("")
    console.log("=".repeat(50))
    console.log("OpenSearch API Server")
    console.log("=".repeat(50))
    console.log("")
    console.log("API Endpoint:    http://localhost:" + port + "/v1/chat/completions")
    console.log("Models:          http://localhost:" + port + "/v1/models")
    console.log("Default Model:   qwen2.5:coder7b")
    console.log("")
    
    if (!noWebUI) {
      console.log("OpenWebUI:         http://localhost:3000")
      console.log("")
      console.log("To connect OpenWebUI to OpenSearch:")
      console.log("1. Go to http://localhost:3000 -> Settings -> Connections")
      console.log("2. Add OpenAI Compatible API")
      console.log("   URL: http://host.docker.internal:" + port)
      console.log("   API Key: opensearch-local")
      console.log("")
    }
    
    const opts = await resolveNetworkOptions(args)
    opts.port = port
    
    if (apiOnly && Flag.OPENCODE_EXPERIMENTAL_HTTPAPI) {
      console.log("Starting in API-only mode...")
    }
    
    const server = await Server.listen(opts)
    console.log(`Server listening on http://${server.hostname}:${server.port}`)
    
    if (!noWebUI && !apiOnly) {
      await startOpenWebUI()
    }
    
    console.log("")
    console.log("Server ready!")
    console.log("")
    
    await new Promise(() => {})
    await server.stop()
  },
})
