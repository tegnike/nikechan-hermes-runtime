#!/bin/bash
# Fetch recent messages from all Discord channels in the server
# Called by cron job — outputs JSON to stdout, progress to stderr

CHANNEL_DIR="/Users/nikenike/.hermes/profiles/nikechandiscord/channel_directory.json"
DISCORD_HISTORY="/Users/nikenike/.hermes/bin/discord-history"
GUILD_ID="1404689195150217217"
LIMIT=30
MINUTES_AGO=10

export FROM_TIME=$(date -u -v-${MINUTES_AGO}M +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "${MINUTES_AGO} minutes ago" +%Y-%m-%dT%H:%M:%SZ)

echo "Fetching messages from last ${MINUTES_AGO} minutes (since ${FROM_TIME})..." >&2

python3 << 'PYEOF'
import json, subprocess, sys, os

channel_dir = "/Users/nikenike/.hermes/profiles/nikechandiscord/channel_directory.json"
history_cmd = "/Users/nikenike/.hermes/bin/discord-history"
guild = "1404689195150217217"
limit = 30
from_time = os.environ.get("FROM_TIME", "")

with open(channel_dir) as f:
    data = json.load(f)

channels = [c for c in data.get("platforms", {}).get("discord", []) if c.get("type") == "channel"]

results = []
for ch in channels:
    ch_id = ch["id"]
    ch_name = ch["name"]
    try:
        result = subprocess.run(
            [history_cmd, "fetch", "--channel", ch_id, "--guild", guild, "--from", from_time, "--limit", str(limit)],
            capture_output=True, text=True, timeout=30
        )
        if result.stdout.strip():
            resp = json.loads(result.stdout)
            messages = resp.get("messages", [])
            if messages:
                results.append({
                    "channel_id": ch_id,
                    "channel_name": ch_name,
                    "messages": messages[:limit]
                })
                print(f"  {ch_name}: {len(messages)} messages", file=sys.stderr)
            else:
                print(f"  {ch_name}: 0 messages", file=sys.stderr)
        else:
            print(f"  {ch_name}: empty response", file=sys.stderr)
    except subprocess.TimeoutExpired:
        print(f"  {ch_name}: timeout", file=sys.stderr)
    except Exception as e:
        print(f"  {ch_name}: error - {e}", file=sys.stderr)

print(json.dumps(results, ensure_ascii=False))
PYEOF
