#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  scripts/new-skill.sh PROFILE SKILL_NAME

Create a new managed skill in this repo and link it into the live Hermes
profile. Edit the generated SKILL.md, then commit it.
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
hermes_root="${HERMES_ROOT:-$HOME/.hermes}"
repo="$repo_root/profiles/$profile/skills/$skill"
live="$hermes_root/profiles/$profile/skills/$skill"

if [[ -e "$repo" || -L "$repo" ]]; then
  echo "repo skill already exists: $repo" >&2
  exit 1
fi
if [[ -e "$live" || -L "$live" ]]; then
  echo "live skill already exists: $live" >&2
  echo "Use scripts/adopt-live-skill.sh $profile $skill if this is a live-created skill." >&2
  exit 1
fi

mkdir -p "$repo" "$(dirname "$live")"
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

ln -s "$repo" "$live"

echo "created $profile/$skill"
echo "repo: $repo"
echo "live: $live -> $repo"
echo
git -C "$repo_root" status --short -- "$repo"
