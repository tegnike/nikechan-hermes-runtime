#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
hermes_root="${HERMES_ROOT:-$HOME/.hermes}"
profiles=("nikechandiscord" "nikechanmain")
managed_skills=("discord-summary" "discord-message-search" "discord-reminder" "discord-freeze")
managed_plugins=("nikechan-discord-routing")
failed=0

check_link() {
  local src="$1"
  local dst="$2"
  if [[ ! -L "$dst" ]]; then
    echo "not linked: $dst"
    failed=1
    return
  fi
  local current
  current="$(readlink "$dst")"
  if [[ "$current" != "$src" ]]; then
    echo "wrong link: $dst -> $current (expected $src)"
    failed=1
    return
  fi
  echo "ok: $dst"
}

check_link "$repo_root/bin/discord-history" "$hermes_root/bin/discord-history"
check_link "$repo_root/bin/discord-freeze" "$hermes_root/bin/discord-freeze"
check_link "$repo_root/bin/nikechan-emotion" "$hermes_root/bin/nikechan-emotion"
check_link "$repo_root/hermes-scripts" "$hermes_root/scripts"

for profile in "${profiles[@]}"; do
  src_profile="$repo_root/profiles/$profile"
  dst_profile="$hermes_root/profiles/$profile"
  check_link "$src_profile/config.yaml" "$dst_profile/config.yaml"
  check_link "$src_profile/SOUL.md" "$dst_profile/SOUL.md"
  check_link "$src_profile/memories" "$dst_profile/memories"
  for skill in "${managed_skills[@]}"; do
    check_link "$src_profile/skills/$skill" "$dst_profile/skills/$skill"
  done
  for plugin in "${managed_plugins[@]}"; do
    check_link "$src_profile/plugins/$plugin" "$dst_profile/plugins/$plugin"
  done
done

echo
git -C "$repo_root" status --short --branch
exit "$failed"
