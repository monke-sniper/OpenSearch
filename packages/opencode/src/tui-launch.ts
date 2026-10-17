#!/usr/bin/env node
// Direct launcher that starts TUI
import { tui } from "./src/cli/cmd/tui/app"

tui({
  directory: process.cwd(),
  model: undefined,
  mode: "full",
  continue: undefined,
  session: undefined,
  share: undefined,
  agent: "build",
  title: undefined,
  format: "default",
  thinking: undefined,
  dangerouslySkipPermissions: false,
  port: undefined,
  attach: undefined,
  attachAuthPassword: undefined,
  onReady: undefined,
  version: undefined,
}).catch(console.error)