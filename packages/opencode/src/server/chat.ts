import { webSearch } from "../tool"
import { Log } from "../util"
import type { RequestHandler } from "hono"

const log = { info: (...args: any[]) => console.log("[chat-api]", ...args), error: (...args: any[]) => console.error("[chat-api]", ...args) }

function parseModelString(modelStr: string): { provider: string; model: string } {
  if (modelStr.includes(":")) {
    const [provider, model] = modelStr.split(":")
    return { provider, model }
  }
  return { provider: "ollama", model: modelStr }
}

async function callOllama(messages: any[], model: string): Promise<any> {
  const ollamaBase = process.env.OLLAMA_BASE_URL ?? "http://localhost:11434"
  const ollamaModel = model.includes(":") ? model.split(":")[1] : model
  
  const response = await fetch(`${ollamaBase}/chat/completions`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model: ollamaModel,
      messages,
      stream: false,
    }),
  })
  
  if (!response.ok) {
    const err = await response.text()
    throw new Error(`Ollama error: ${response.status} ${err}`)
  }
  
  return response.json()
}

async function callOpenAI(messages: any[], model: string, apiKey: string): Promise<any> {
  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages,
      stream: false,
    }),
  })
  
  if (!response.ok) {
    const err = await response.text()
    throw new Error(`OpenAI error: ${response.status} ${err}`)
  }
  
  return response.json()
}

async function webSearch(query: string): Promise<string> {
  const results = await webSearch(query)
  return results
}

export async function handleChatCompletions(payload: any): Promise<any> {
  const model = payload.model ?? "qwen2.5:coder7b"
  const messages = payload.messages ?? []
  const stream = payload.stream ?? false
  const tools = payload.tools ?? []
  
  if (!Array.isArray(messages) || messages.length === 0) {
    return { error: { message: "messages required", type: "invalid_request_error", code: "400" } }
  }
  
  const lastUserMsg = [...messages].reverse().find((m: any) => m.role === "user")
  const userPrompt = lastUserMsg?.content ?? ""
  
  log.info(`[${model}] ${userPrompt.slice(0, 60)}`)
  
  let responseContent = ""
  let toolCalls: any[] = []
  
  const hasSearchTool = tools.some((t: any) => t.function?.name === "web_search" || t.function?.name === "search")
  
  if (hasSearchTool) {
    log.info(`[${model}] Calling search tool`)
    const searchResults = await webSearch(userPrompt)
    responseContent = searchResults
  }
  
  try {
    const ollamaModel = model.includes(":") ? model.split(":")[1] : model
    
    const ollamaMessages = [...messages]
    
    if (responseContent) {
      const lastIdx = ollamaMessages.findIndex((m: any) => m.role === "user")
      if (lastIdx >= 0) {
        ollamaMessages[lastIdx] = {
          ...ollamaMessages[lastIdx],
          content: ollamaMessages[lastIdx].content + `\n\nContext from search:\n${responseContent}`,
        }
      }
    }
    
    const ollamaResult = await callOllama(ollamaMessages, ollamaModel)
    responseContent = ollamaResult.choices?.[0]?.message?.content ?? ""
  } catch (e) {
    log.error(`LLM error: ${e}`)
    responseContent = `Error: ${e instanceof Error ? e.message : String(e)}`
  }
  
  return {
    id: `chatcmpl-${Date.now()}`,
    object: "chat.completion",
    created: Date.now(),
    model,
    choices: [
      {
        index: 0,
        message: {
          role: "assistant",
          content: responseContent,
        },
        finish_reason: "stop",
      },
    ],
    usage: {
      prompt_tokens: 100,
      completion_tokens: 100,
      total_tokens: 200,
    },
  }
}

export async function handleListModels(): Promise<any> {
  return {
    object: "list",
    data: [
      { id: "qwen2.5:coder7b", object: "model", owned_by: "opencode", root: "qwen2.5:coder7b", parent: null },
    ],
  }
}

export function streamChatCompletions(res: any, payload: any): Streamable {
  const stream = new Stream()
  
  handleChatCompletions(payload)
    .then((result) => {
      const chunk = buildStreamChunk("chat", "0", result)
      res.write(`data: ${JSON.stringify(chunk)}\n\n`)
      res.write("data: [DONE]\n\n")
      res.end()
    })
    .catch((e) => {
      log.error(`Stream error: ${e}`)
      const errorChunk = { error: { message: e.message } }
      res.write(`data: ${JSON.stringify(errorChunk)}\n\n`)
      res.end()
    })
  
  return stream
}

function buildStreamChunk(type: string, id: string, data: any): any {
  return {
    object: type,
    id,
    created: Date.now(),
    data,
  }
}