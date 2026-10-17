# OpenSearch: Create private repo and push patch to GitHub using PAT
param([string]$Token = $env:GITHUB_TOKEN)
if ([string]::IsNullOrWhiteSpace($Token)) {
  Write-Error "Please set GITHUB_TOKEN environment variable with a GitHub PAT"
  exit 1
}

$headers = @{ Authorization = "Bearer $Token"; Accept = "application/vnd.github+json" }

$body = '{"name":"opensearch","private":true,"description":"OpenSearch CLI + Node backend with streaming."}'

try {
  $resp = Invoke-RestMethod -Method Post -Uri 'https://api.github.com/user/repos' -Headers $headers -Body $body -ContentType 'application/json'
  $repoUrl = $resp.html_url
  Write-Host "Repo created: $repoUrl"
} catch {
  Write-Error "Failed to create repo: $_"
  exit 1
}

Write-Host "Now pushing local changes to main..."

if ((Test-Path .git) -and (git rev-parse --verify main 2>$null)) {
  git add -A
  git commit -m "End-to-end: robust dynamic base guards and streaming patch"
  git remote remove origin 2>$null
  $owner = (Invoke-RestMethod -Method Get -Uri $repoUrl.Replace('https://','https://$Token@') -Headers $headers).owner.login
  $repoName = (Split-Path $repoUrl -Leaf -Resolve).Replace('.git','')
  $remote = $repoUrl.Replace('https://','https://'+$Token+'@')
  git remote add origin $remote
  git branch -M main
  git push -u origin main
} else {
  Write-Error "No git repo found at current directory or main branch missing."
  exit 1
}

Write-Host "Create a patch branch and PR via REST (not shown here). You can create a patch branch and PR via REST or gh pr commands now."
