#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
hermes_root="${HERMES_ROOT:-$HOME/.hermes}"
profile_root="$hermes_root/profiles"
bin_dir="$hermes_root/bin"
profiles=("nikechandiscord" "nikechanmain")

mkdir -p "$bin_dir" "$profile_root"

install -m 755 "$repo_root/bin/discord-history" "$bin_dir/discord-history"
install -m 755 "$repo_root/bin/discord-freeze" "$bin_dir/discord-freeze"
install -m 755 "$repo_root/bin/nikechan-emotion" "$bin_dir/nikechan-emotion"

for profile in "${profiles[@]}"; do
  src="$repo_root/profiles/$profile"
  dst="$profile_root/$profile"
  mkdir -p "$dst"

  install -m 600 "$src/config.yaml" "$dst/config.yaml"
  install -m 600 "$src/SOUL.md" "$dst/SOUL.md"

  rsync -a --delete "$src/memories/" "$dst/memories/"
  rsync -a --delete "$src/skills/" "$dst/skills/"
  rsync -a --delete "$src/plugins/" "$dst/plugins/"

  if [[ ! -f "$dst/.env" ]]; then
    install -m 600 "$src/.env.example" "$dst/.env.example"
    echo "Created $dst/.env.example. Create $dst/.env with real secrets before starting this profile." >&2
  else
    install -m 600 "$src/.env.example" "$dst/.env.example"
  fi

  if [[ "${RESTART:-0}" == "1" ]]; then
    sudo launchctl kickstart -k "system/ai.hermes.gateway-$profile"
  fi
done
