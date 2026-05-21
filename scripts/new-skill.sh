#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  scripts/new-skill.sh PROFILE SKILL_NAME

Create a new skill in this repo. The live Hermes profile skills directory is
symlinked to this repo, so the skill appears in live immediately. Restart the
gateway when Hermes needs to reload the skill registry.
EOF
}

if [[ $# -ne 2 ]]; then
  usage
  exit 2
fi

profile="$1"
skill="$2"

case "$profile" in
  nikechandiscord|nikechanmain) ;;
  *)
    echo "unknown profile: $profile" >&2
    exit 2
    ;;
esac

if [[ "$skill" == *"/"* || "$skill" == "." || "$skill" == ".." || -z "$skill" ]]; then
  echo "invalid skill name: $skill" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo="$repo_root/profiles/$profile/skills/$skill"

if [[ -e "$repo" || -L "$repo" ]]; then
  echo "repo skill already exists: $repo" >&2
  exit 1
fi

mkdir -p "$repo"
cat > "$repo/SKILL.md" <<EOF
---
name: $skill
description: "TODO: describe when Hermes should use this skill."
platforms: [macos, linux]
metadata:
  hermes:
    tags: []
    category: custom
---

# $skill

TODO: write the workflow.
EOF

echo "created $profile/$skill"
echo "repo/live: $repo"
echo
git -C "$repo_root" status --short -- "$repo"
