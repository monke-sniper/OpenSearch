# OpenSearch - Product Search Agent with OpenCode TUI

A modified version of OpenCode configured for product/search discovery instead of coding.

## What's Different

- **Default agent**: Uses "search" agent instead of "build" agent
- **Search tools**: ddg_search, ebay_search tools available
- **Command**: `opensearch` or `opensearch "your query"`

## Installation

```powershell
# From the opensearch directory
cd C:\Users\idkch\opensearch

# Install dependencies
bun install

# Add ddgs package
bun add ddgs
```

## Usage

```powershell
# Run with query (auto-selects search agent)
opensearch "rtx 5090 used white"

# Or use the bin directly
bun run packages/opencode/src/index.ts --agent search "rtx 5090"

# Interactive mode
opensearch
```

## Commands

```powershell
# Search for products
opensearch "land for 10 dollars"
opensearch "gaming laptop under 1000"
opensearch "iphone 15 used good condition"

# Attach to a server
opensearch serve --port 4096
opensearch attach http://localhost:4096 --prompt "rtx 5090"
```

## Tools Available

- **ddg_search**: Search DuckDuckGo for products/info
- **ebay_search**: Search eBay for product listings with prices

## Running

```powershell
cd C:\Users\idkch\opensearch
bun run dev
```

This opens the EXACT OpenCode TUI but with the search agent and tools.

## Files Changed

- `packages/opencode/src/tool/search.ts` - New search tools
- `packages/opencode/src/agent/prompt/search.txt` - Search agent prompt
- `packages/opencode/src/agent/agent.ts` - Added search agent
- `packages/opencode/src/tool/registry.ts` - Registered search tools
- `packages/opencode/bin/opensearch` - New CLI command
- `packages/opencode/package.json` - Added opensearch bin