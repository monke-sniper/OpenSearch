#!/usr/bin/env node
// End-to-end GitHub push of opensearch with patch and PR
// This script creates a private repo, commits local changes, pushes, and opens a PR.

const https = require('https')
const { execSync } = require('child_process')
const fs = require('fs')
const path = require('path')

const TOKEN = process.env.GITHUB_TOKEN || process.env.GITHUB_PAT || ""
if (!TOKEN) {
  console.error("Please provide a GitHub token in GITHUB_TOKEN env var or GITHUB_PAT.")
  process.exit(1)
}

function post(url, body) {
  return new Promise((resolve, reject) => {
    const data = Buffer.from(JSON.stringify(body))
    const u = new URL(url)
    const options = {
      hostname: u.hostname,
      path: u.pathname + (u.search || ''),
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length,
        'Authorization': `token ${TOKEN}`,
        'Accept': 'application/vnd.github+json'
      }
    }
    const req = https.request(options, (res) => {
      let raw = ''
      res.setEncoding('utf8')
      res.on('data', (chunk) => raw += chunk)
      res.on('end', () => {
        try {
          const parsed = JSON.parse(raw)
          resolve(parsed)
        } catch (e) {
          reject(e)
        }
      })
    })
    req.on('error', (e) => reject(e))
    req.write(data)
    req.end()
  })
}

async function ensureGitRepo() {
  try {
    execSync('git rev-parse --is-inside-work-tree', { stdio: 'ignore' })
  } catch {
    execSync('git init', { stdio: 'inherit' })
  }
}

async function main() {
  // 1) Create repo
  const repoBody = { name: 'opensearch', private: true, description: 'OpenSearch CLI + Node backend with streaming.' }
  const resp = await post('https://api.github.com/user/repos', repoBody)
  const htmlUrl = resp.html_url
  const cloneUrl = resp.clone_url
  if (!htmlUrl || !cloneUrl) {
    console.error('Failed to create repo, response:', resp)
    process.exit(1)
  }

  // Parse owner/name from URL
  const m = cloneUrl.match(/github.com\/(.*)\/(.*)\.git/)
  const owner = m ? m[1] : 'OWNER'
  const repo = m ? m[2] : 'opensearch'

  // 2) Setup local remote
  try { execSync('git rev-parse --verify main', { stdio: 'ignore' }) } catch { /* ignore */ }
  try { execSync('git rev-parse --verify patch/opensearch-end2end-fix', { stdio: 'ignore' }) } catch {}
  execSync('git add -A', { stdio: 'inherit' })
  try {
    execSync('git commit -m "End-to-end: robust dynamic base guards and streaming"', { stdio: 'inherit' })
  } catch { /* ignore if nothing to commit */ }

  // remote with token (avoid exposing in logs)
  const remote = cloneUrl.replace('https://', `https://${TOKEN}@`)
  try { execSync(`git remote remove origin`, { stdio: 'ignore' }) } catch {}
  execSync(`git remote add origin ${remote}`, { stdio: 'inherit' })
  execSync('git branch -M main', { stdio: 'inherit' })
  execSync('git push -u origin main', { stdio: 'inherit' })

  // 3) Create patch branch and push
  const patchBranch = 'patch/end2end-fix'
  try {
    execSync(`git checkout -b ${patchBranch}`, { stdio: 'inherit' })
  } catch { /* already on branch */ }
  execSync(`git push -u origin ${patchBranch}`, { stdio: 'inherit' })

  // 4) Create PR
  const prBody = {
    title: 'End-to-end fix: robust dynamic base guards and streaming',
    head: patchBranch,
    base: 'main',
    body: 'Root cause: dynamic base-extends crash. Guarded across Agent/ToolRegistry/Worktree and v2 modules. Windows TS cleanup. Verify end-to-end streaming.'
  }
  const pr = await post(`https://api.github.com/repos/${owner}/${repo}/pulls`, prBody)
  console.log('PR URL:', pr.html_url)
}

main().catch((e) => {
  console.error('ERROR:', e && e.message ? e.message : e)
  process.exit(1)
})
