#!/usr/bin/env bash
#
# One-time setup of branch protection on main.
#
# Requires the GitHub CLI, authenticated:
#   winget install --id GitHub.cli
#   gh auth login
#
# Branch protection on a free plan requires the repository to be PUBLIC.
# That is already the intended state here: this is a portfolio project, and a
# public repository also gets unlimited GitHub Actions minutes.
#
# Usage:  bash .github/setup-branch-protection.sh

set -euo pipefail

REPO="${1:-AlejandroSosaDev/ApexMetrics}"
BRANCH="main"

echo "Applying branch protection to ${REPO}@${BRANCH}"

# Notes on the choices below:
#
# required_approving_review_count: 0
#   A solo developer cannot approve their own pull request. Requiring one
#   approval would make main unmergeable rather than safer. The review gate
#   here is human intent — Alejandro merges every PR manually — not a count.
#
# enforce_admins: false
#   Deliberate. With no second maintainer, enforcing rules on admins turns any
#   misconfiguration into a locked repository with no way back through the API.
#
# required_status_checks: null
#   No workflows exist yet. Requiring checks that never report would block
#   every pull request. APEX-56 adds the workflows and then wires them in;
#   see the bottom of this file for that follow-up command.
#
# required_linear_history: true
#   Squash or rebase only. Keeps history readable as a narrative of the work,
#   which for a portfolio repository is part of the deliverable.

gh api -X PUT "repos/${REPO}/branches/${BRANCH}/protection" \
  --input - <<'JSON'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 0,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": false
}
JSON

echo "Enabling automatic deletion of merged branches"
gh api -X PATCH "repos/${REPO}" -F delete_branch_on_merge=true >/dev/null

echo
echo "Done. Verify with:"
echo "  gh api repos/${REPO}/branches/${BRANCH}/protection | jq"
echo
echo "After APEX-56 adds the workflows, require them:"
cat <<'FOLLOWUP'
  gh api -X PATCH "repos/OWNER/REPO/branches/main/protection/required_status_checks" \
    --input - <<'JSON'
  {
    "strict": true,
    "contexts": ["backend", "frontend", "lint"]
  }
JSON
FOLLOWUP
