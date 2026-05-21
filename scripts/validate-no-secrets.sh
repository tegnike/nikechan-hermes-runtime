#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v rg >/dev/null 2>&1; then
  echo "rg is required for this check" >&2
  exit 2
fi

patterns=(
  'DISCORD_BOT_TOKEN=[A-Za-z0-9._-]+'
  'sk-[A-Za-z0-9_-]{20,}'
  '"access_token":'
  'apiKey'
  'DASHSCOPE_API_KEY=sk-'
  'ALIBABA_CODING_PLAN_API_KEY=sk-'
)

failed=0
for pattern in "${patterns[@]}"; do
  if rg -n --hidden --glob '!profiles/*/.env.example' --glob '!scripts/validate-no-secrets.sh' "$pattern" .; then
    failed=1
  fi
done

if [[ "$failed" == "1" ]]; then
  echo "Potential secret material found. Review before committing." >&2
  exit 1
fi

echo "No obvious secrets found."
