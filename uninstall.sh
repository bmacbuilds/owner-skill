#!/usr/bin/env bash
# Removes Owner: only the skill folders our installer marked as ours. Nothing you made with it is ever touched.
set -euo pipefail
MARKER=".owner-install"
COMMANDS="ap-processor cash-flow-snapshot close-month invoice-chase month-end-prep pay-the-bills payroll-prep plan-payroll report-builder report-pack tax-prep tax-season-organizer call-list crm-autopilot grow-pipeline lead-finder lead-triage outreach-composer reactivate speed-to-lead ad-manager canva-creator content-strategy growth-pulse marketing-monday review-reputation seo-ai-visibility social-content-engine contract-review grant-rfp-writer proposal-builder ticket-deflector hiring-screener inbox-manager inventory-planner job-post-builder restock business-pulse monday-brief smb-onboard smb-router brand-style build-agent build-connector"   # written by scripts/sync.py from skill.json
removed=0
for base in owner bmac-owner; do
  for name in "$base" $(for s in $COMMANDS; do printf '%s-%s ' "$base" "$s"; done); do
    dir="$HOME/.claude/skills/$name"
    [ -e "$dir" ] || continue
    if [ -f "$dir/$MARKER" ]; then
      rm -rf "$dir"; removed=$((removed + 1))
    else
      printf 'Left %s alone: Owner did not install it.\n' "$dir"
    fi
  done
done
if [ "$removed" -gt 0 ]; then printf 'Removed Owner (%s skill folders).\n' "$removed"; else printf 'Owner was not installed.\n'; fi
