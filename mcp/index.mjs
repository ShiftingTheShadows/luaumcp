#!/usr/bin/env node

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import { z } from 'zod'

const API = 'https://shadowexec.vercel.app/api'
const POLL_MS = 500
const TIMEOUT_MS = 30000

const keyArg = process.argv.find((a, i) => process.argv[i - 1] === '--key')
if (!keyArg) {
  process.stderr.write('Usage: shadowexec-mcp --key <session-key>\n')
  process.exit(1)
}
const KEY = keyArg

async function api(path, opts = {}) {
  const url = `${API}${path}`
  const r = await fetch(url, {
    headers: { 'Content-Type': 'application/json', ...opts.headers },
    ...opts
  })
  return r.json()
}

const server = new McpServer({
  name: 'shadowexec',
  version: '1.0.0'
})

server.tool(
  'execute_luau',
  'Execute Luau code on the connected Roblox client. Submits code, waits for execution result, returns output. Use for running scripts, querying game state, reverse engineering games, etc.',
  { code: z.string().describe('Luau code to execute on the Roblox client') },
  async ({ code }) => {
    const submit = await api('/code', {
      method: 'POST',
      body: JSON.stringify({ code, key: KEY })
    })

    if (!submit.id) {
      return { content: [{ type: 'text', text: 'Submit failed: ' + JSON.stringify(submit) }] }
    }

    const id = submit.id
    const start = Date.now()

    while (Date.now() - start < TIMEOUT_MS) {
      const poll = await api(`/code?id=${id}&key=${encodeURIComponent(KEY)}`)

      if (poll.status === 'done') {
        const status = poll.success ? 'SUCCESS' : 'ERROR'
        const output = poll.output || '(no output)'
        return {
          content: [{ type: 'text', text: `[${status}]\n${output}` }]
        }
      }

      await new Promise(r => setTimeout(r, POLL_MS))
    }

    return { content: [{ type: 'text', text: 'Timeout: no response from client after 30s. Is the script running in-game?' }] }
  }
)

server.tool(
  'read_console',
  'Read recent console output from the connected Roblox client. Returns log entries with timestamps and types (output/warning/error/info/join).',
  { limit: z.number().optional().default(50).describe('Max entries to return') },
  async ({ limit }) => {
    const data = await api(`/log?key=${encodeURIComponent(KEY)}`)

    if (!data.logs || data.logs.length === 0) {
      return { content: [{ type: 'text', text: 'No console entries.' }] }
    }

    const entries = data.logs.slice(-limit).map(e => {
      const time = new Date(e.time).toLocaleTimeString()
      const type = (e.type || 'output').toUpperCase()
      let text = e.text
      if (e.type === 'join') {
        try {
          const info = JSON.parse(e.text)
          text = `Player joined: ${info.display} (@${info.name}, ID: ${info.id})`
        } catch (_) {}
      }
      return `[${time}] [${type}] ${text}`
    })

    return { content: [{ type: 'text', text: entries.join('\n') }] }
  }
)

server.tool(
  'get_status',
  'Check if a Roblox client is connected by looking for recent join logs.',
  {},
  async () => {
    const data = await api(`/log?key=${encodeURIComponent(KEY)}`)

    if (!data.logs || data.logs.length === 0) {
      return { content: [{ type: 'text', text: 'No client connected. Make sure the script is running in-game with this session key.' }] }
    }

    const joins = data.logs.filter(e => e.type === 'join')
    if (joins.length === 0) {
      return { content: [{ type: 'text', text: 'Logs exist but no join events found. Client may have connected before logging started.' }] }
    }

    const last = joins[joins.length - 1]
    try {
      const info = JSON.parse(last.text)
      const ago = Math.round((Date.now() - last.time) / 1000)
      return {
        content: [{
          type: 'text',
          text: `Client connected: ${info.display} (@${info.name}, ID: ${info.id})\nLast join: ${ago}s ago`
        }]
      }
    } catch (_) {
      return { content: [{ type: 'text', text: 'Client connected (could not parse join info).' }] }
    }
  }
)

const transport = new StdioServerTransport()
await server.connect(transport)
