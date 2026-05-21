#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
hermes_root="${HERMES_ROOT:-$HOME/.hermes}"
profile_root="$hermes_root/profiles"
bin_dir="$hermes_root/bin"
backup_root="$hermes_root/backups/runtime-link-$(date +%Y%m%d-%H%M%S)"
profiles=("nikechandiscord" "nikechanmain")
managed_skills=(
  "discord-summary"
  "discord-message-search"
  "discord-reminder"
  "discord-freeze"
)
managed_plugins=(
  "nikechan-discord-routing"
)

backup_path_for() {
  local dst="$1"
  local rel="${dst#$hermes_root/}"
  printf '%s/%s' "$backup_root" "$rel"
}

replace_with_symlink() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" ]]; then
    echo "source missing: $src" >&2
    exit 1
  fi

  mkdir -p "$(dirname "$dst")"

  if [[ -L "$dst" ]]; then
    local current
    current="$(readlink "$dst")"
    if [[ "$current" == "$src" ]]; then
      return
    fi
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    local backup
    backup="$(backup_path_for "$dst")"
    mkdir -p "$(dirname "$backup")"
    mv "$dst" "$backup"
    echo "backed up $dst -> $backup"
  fi

  ln -s "$src" "$dst"
  echo "linked $dst -> $src"
}

mkdir -p "$bin_dir" "$profile_root"

replace_with_symlink "$repo_root/bin/discord-history" "$bin_dir/discord-history"
replace_with_symlink "$repo_root/bin/discord-freeze" "$bin_dir/discord-freeze"
replace_with_symlink "$repo_root/bin/nikechan-emotion" "$bin_dir/nikechan-emotion"
replace_with_symlink "$repo_root/hermes-scripts" "$hermes_root/scripts"

for profile in "${profiles[@]}"; do
  src_profile="$repo_root/profiles/$profile"
  dst_profile="$profile_root/$profile"
  mkdir -p "$dst_profile/skills" "$dst_profile/plugins"

  replace_with_symlink "$src_profile/config.yaml" "$dst_profile/config.yaml"
  replace_with_symlink "$src_profile/SOUL.md" "$dst_profile/SOUL.md"
  replace_with_symlink "$src_profile/memories" "$dst_profile/memories"

  for skill in "${managed_skills[@]}"; do
    replace_with_symlink "$src_profile/skills/$skill" "$dst_profile/skills/$skill"
  done

  for plugin in "${managed_plugins[@]}"; do
    replace_with_symlink "$src_profile/plugins/$plugin" "$dst_profile/plugins/$plugin"
  done

  if [[ ! -f "$dst_profile/.env" ]]; then
    cp -n "$src_profile/.env.example" "$dst_profile/.env.example"
    echo "missing $dst_profile/.env; copied .env.example only" >&2
  fi
done

if [[ "${RESTART:-0}" == "1" ]]; then
  for profile in "${profiles[@]}"; do
    sudo launchctl kickstart -k "system/ai.hermes.gateway-$profile"
  done
fi
