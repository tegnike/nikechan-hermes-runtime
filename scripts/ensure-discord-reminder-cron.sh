#!/usr/bin/env bash
set -euo pipefail

profile="${1:-nikechandiscord}"
hermes_root="${HERMES_ROOT:-$HOME/.hermes}"
profile_home="$hermes_root/profiles/$profile"
jobs_file="$profile_home/cron/jobs.json"
script_name="discord-reminder-dispatch.sh"
job_id="nikechan-discord-reminder-dispatch-v1"

mkdir -p "$(dirname "$jobs_file")"
python3 - "$jobs_file" "$job_id" "$script_name" <<'PY'
from __future__ import annotations

import datetime as dt
import json
import sys
from pathlib import Path

jobs_file = Path(sys.argv[1])
job_id = sys.argv[2]
script_name = sys.argv[3]
now = dt.datetime.now().astimezone()

if jobs_file.exists():
    data = json.loads(jobs_file.read_text(encoding='utf-8'))
else:
    data = {'jobs': []}
jobs = data.setdefault('jobs', [])

job = next((item for item in jobs if item.get('id') == job_id), None)
created = False
if job is None:
    job = {
        'id': job_id,
        'name': 'discord-reminder-dispatcher',
        'prompt': 'Discordリマインダーの軽量ディスパッチャ。通常は出力しません。',
        'skills': [],
        'skill': None,
        'model': None,
        'provider': None,
        'base_url': None,
        'script': script_name,
        'no_agent': True,
        'context_from': None,
        'schedule': {'kind': 'interval', 'minutes': 1, 'display': 'every 1m'},
        'schedule_display': 'every 1m',
        'repeat': {'times': None, 'completed': 0},
        'enabled': True,
        'state': 'scheduled',
        'paused_at': None,
        'paused_reason': None,
        'created_at': now.isoformat(),
        'next_run_at': (now + dt.timedelta(minutes=1)).isoformat(),
        'last_run_at': None,
        'last_status': None,
        'last_error': None,
        'last_delivery_error': None,
        'deliver': 'discord:1404724174890602496',
        'origin': {
            'platform': 'discord',
            'chat_id': '1404724174890602496',
            'chat_name': 'AIニケちゃん / #aiニケちゃんbot',
            'thread_id': None,
        },
        'enabled_toolsets': ['terminal'],
        'workdir': None,
        'profile': None,
    }
    jobs.append(job)
    created = True
else:
    job.update({
        'name': 'discord-reminder-dispatcher',
        'script': script_name,
        'no_agent': True,
        'schedule': {'kind': 'interval', 'minutes': 1, 'display': 'every 1m'},
        'schedule_display': 'every 1m',
        'enabled': True,
        'state': 'scheduled',
        'deliver': job.get('deliver') or 'discord:1404724174890602496',
        'enabled_toolsets': ['terminal'],
    })
    job.setdefault('next_run_at', (now + dt.timedelta(minutes=1)).isoformat())
    job.setdefault('repeat', {'times': None, 'completed': 0})

data['updated_at'] = now.isoformat()
jobs_file.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(('created' if created else 'updated') + f': {job_id}')
PY
