#!/usr/bin/env bash
set -euo pipefail

owner="${GITHUB_OWNER:-ttc9082}"
repo="${GITHUB_REPO:-notch-codex}"
full_name="${owner}/${repo}"
remote_url="https://github.com/${full_name}.git"
description="macOS notch-adjacent Codex usage meter"

git remote remove origin 2>/dev/null || true
git remote add origin "${remote_url}"

if command -v gh >/dev/null 2>&1; then
  if ! gh repo view "${full_name}" >/dev/null 2>&1; then
    gh repo create "${full_name}" \
      --public \
      --description "${description}" \
      --source . \
      --remote origin
  fi

  git push -u origin main
  exit 0
fi

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  status="$(
    curl -sS -o /tmp/notch-codex-repo-check.json -w "%{http_code}" \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/repos/${full_name}"
  )"

  if [[ "${status}" == "404" ]]; then
    curl -sS \
      -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      -X POST https://api.github.com/user/repos \
      -d "{\"name\":\"${repo}\",\"description\":\"${description}\",\"private\":false}" \
      >/tmp/notch-codex-create-repo.json
  elif [[ "${status}" != "200" ]]; then
    cat /tmp/notch-codex-repo-check.json >&2
    exit 1
  fi

  git push -u "https://x-access-token:${GITHUB_TOKEN}@github.com/${full_name}.git" main
  exit 0
fi

cat >&2 <<EOF
Cannot publish ${full_name}: neither gh nor GITHUB_TOKEN is available.

Options:
  1. Install and authenticate GitHub CLI, then run:
     gh auth login
     scripts/publish-github.sh

  2. Export a fine-grained GitHub token with Contents and Metadata access:
     export GITHUB_TOKEN=...
     scripts/publish-github.sh

  3. Create https://github.com/new manually, then run:
     git push -u origin main
EOF
exit 1
