# Windows PATH helper for gh CLI
# Adds gh to PATH for the current session and persists for future sessions

$ghPaths = @(
  "$env:ProgramFiles\\GitHub CLI\\bin",
  "$env:ProgramFiles (x86)\\GitHub CLI\\bin",
  "C:\\Program Files\\GitHub CLI\\bin",
  "C:\\Program Files (x86)\\GitHub CLI\\bin"
)

foreach ($p in $ghPaths) {
  if (Test-Path $p) {
    if (-not ($Env:PATH -like "*${p}*")) {
      $Env:PATH = "$Env:PATH;$p"
      Write-Host "Session PATH updated: $p"
    }
  }
}

if (Get-Command gh -ErrorAction SilentlyContinue) {
  Write-Host "gh found: $((Get-Command gh).Source)"
} else {
  Write-Host "gh not found. Please install GitHub CLI: https://cli.github.com/"
}

# Persist for future PowerShell sessions (User scope)
$userPath = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
foreach ($p in $ghPaths) {
  if (Test-Path $p -and -not ($userPath -like "*$p*")) {
    $newPath = if ([string]::IsNullOrEmpty($userPath)) { $p } else { "$userPath;$p" }
    [Environment]::SetEnvironmentVariable("PATH", $newPath, [EnvironmentVariableTarget]::User)
    Write-Host "Persistent PATH updated: $p (User scope)"
  }
}
