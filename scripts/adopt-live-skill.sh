#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  scripts/adopt-live-skill.sh PROFILE SKILL_NAME

Adopt an old live-created skill into this git repo. In the current setup the
live skills directory itself is symlinked to this repo, so new live-created
skills are already git-visible and usually do not need this command.

Examples:
  scripts/adopt-live-skill.sh nikechandiscord my-new-skill
  scripts/adopt-live-skill.sh nikechanmain discord-summary
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
live="$hermes_root/profiles/$profile/skills/$skill"
repo="$repo_root/profiles/$profile/skills/$skill"

if [[ -L "$hermes_root/profiles/$profile/skills" ]]; then
  current_dir="$(readlink "$hermes_root/profiles/$profile/skills")"
  if [[ "$current_dir" == "$repo_root/profiles/$profile/skills" ]]; then
    if [[ -e "$repo" || -L "$repo" ]]; then
      echo "already managed by skills directory symlink: $repo"
      git -C "$repo_root" status --short -- "$repo"
      exit 0
    fi
    echo "skill does not exist in managed skills directory: $repo" >&2
    exit 1
  fi
fi

if [[ ! -e "$live" && ! -L "$live" ]]; then
  echo "live skill does not exist: $live" >&2
  exit 1
fi

if [[ -L "$live" ]]; then
  current="$(readlink "$live")"
  if [[ "$current" == "$repo" ]]; then
    echo "already managed: $live -> $repo"
    exit 0
  fi
  echo "live path is already a symlink to another target: $live -> $current" >&2
  exit 1
fi

if [[ -e "$repo" ]]; then
  echo "repo skill already exists: $repo" >&2
  echo "Refusing to overwrite. Diff manually, then remove or rename one side." >&2
  exit 1
fi

mkdir -p "$(dirname "$repo")"
mv "$live" "$repo"
ln -s "$repo" "$live"

echo "adopted $profile/$skill"
echo "live: $live -> $repo"
echo
git -C "$repo_root" status --short -- "$repo"
