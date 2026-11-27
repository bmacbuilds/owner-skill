# Removes Owner on Windows: only the skill folders our installer marked as ours. Nothing you made with it is ever touched.
$ErrorActionPreference = "Stop"
$Commands = @("ap-processor", "cash-flow-snapshot", "close-month", "invoice-chase", "month-end-prep", "pay-the-bills", "payroll-prep", "plan-payroll", "report-builder", "report-pack", "tax-prep", "tax-season-organizer", "call-list", "crm-autopilot", "grow-pipeline", "lead-finder", "lead-triage", "outreach-composer", "reactivate", "speed-to-lead", "ad-manager", "canva-creator", "content-strategy", "growth-pulse", "marketing-monday", "review-reputation", "seo-ai-visibility", "social-content-engine", "contract-review", "grant-rfp-writer", "proposal-builder", "ticket-deflector", "hiring-screener", "inbox-manager", "inventory-planner", "job-post-builder", "restock", "business-pulse", "monday-brief", "smb-onboard", "smb-router", "brand-style", "build-agent", "build-connector")   # written by scripts/sync.py from skill.json
$removed = 0
foreach ($base in "owner", "bmac-owner") {
  foreach ($name in @($base) + @($Commands | ForEach-Object { "$base-$_" })) {
    $dir = Join-Path $HOME ".claude\skills\$name"
    if (-not (Test-Path -LiteralPath $dir)) { continue }
    if (Test-Path -LiteralPath (Join-Path $dir ".owner-install")) {
      Remove-Item -Recurse -Force -LiteralPath $dir; $removed++
    } else {
      Write-Output "Left $dir alone: Owner did not install it."
    }
  }
}
if ($removed -gt 0) { Write-Output "Removed Owner ($removed skill folders)." } else { Write-Output "Owner was not installed." }
