# OpenSearch
Goal oriented autonomous research (GOAR) CLI tool.

---

## Project structure
```
opensearcher-alpha/
├── .env                    # General env stuff like ollama keys etc and other configuration to be decided - SearNXG or firecrawl self hosted
├── src/
│   ├── main.js             # Orchestrator (The Infinite Loop)
│   ├── graph/
│   │   ├── state.js        # Global 'Found Information' Ledger
│   │   └── controller.js   # Qwen 3.5:9B decision engine
│   ├── tools/
│   │   ├── search_api.js   # Broad search (SearNXG or better alternative)
│   │   ├── deep_scraper.js # Markdown extraction (Firecrawl/Jina)
│   │   └── validator.js    # Goal-Verification logic
│   └── output/
│       └── final_book.md   # The synthesized knowledge base
└── config/
    └── goals.json          # Defined success criteria
```
>Subject to change for optimizations and other things as the project changes

**MORE STUFF WILL BE ADDED HERE IN THE FUTURE AS THE PROJECT GROWS**
