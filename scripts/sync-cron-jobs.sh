#!/usr/bin/env bash
set -euo pipefail

profile="${1:?profile required}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
hermes_root="${HERMES_ROOT:-$HOME/.hermes}"
template_file="$repo_root/profiles/$profile/cron/jobs.template.json"
jobs_file="$hermes_root/profiles/$profile/cron/jobs.json"

if [[ ! -f "$template_file" ]]; then
  exit 0
fi

mkdir -p "$(dirname "$jobs_file")"

python3 - "$template_file" "$jobs_file" <<'PY'
from __future__ import annotations

import datetime as dt
import json
import os
import sys
from pathlib import Path

template_file = Path(sys.argv[1])
jobs_file = Path(sys.argv[2])
now = dt.datetime.now().astimezone()

template = json.loads(template_file.read_text(encoding="utf-8"))
if jobs_file.exists() or jobs_file.is_symlink():
    live = json.loads(jobs_file.read_text(encoding="utf-8"))
else:
    live = {"jobs": []}
if jobs_file.is_symlink():
    jobs_file.unlink()

live_jobs = live.setdefault("jobs", [])
live_by_id = {job.get("id"): job for job in live_jobs if job.get("id")}
next_jobs = []

preserve_keys = {
    "repeat",
    "created_at",
    "next_run_at",
    "last_run_at",
    "last_status",
    "last_error",
    "last_delivery_error",
}


def next_run_for(job: dict) -> str:
    schedule = job.get("schedule") or {}
    if schedule.get("kind") == "interval":
        minutes = int(schedule.get("minutes") or 1)
        return (now + dt.timedelta(minutes=minutes)).isoformat()
    return now.isoformat()


for template_job in template.get("jobs", []):
    job_id = template_job.get("id")
    merged = dict(template_job)
    existing = live_by_id.get(job_id)
    if existing:
        for key in preserve_keys:
            if key in existing:
                merged[key] = existing[key]
    merged.setdefault("created_at", now.isoformat())
    if not merged.get("next_run_at"):
        merged["next_run_at"] = next_run_for(merged)
    merged.setdefault("last_run_at", None)
    merged.setdefault("last_status", None)
    merged.setdefault("last_error", None)
    merged.setdefault("last_delivery_error", None)
    repeat = merged.setdefault("repeat", {"times": None, "completed": 0})
    repeat.setdefault("completed", 0)
    next_jobs.append(merged)

template_ids = {job.get("id") for job in template.get("jobs", [])}
for live_job in live_jobs:
    if live_job.get("id") not in template_ids:
        next_jobs.append(live_job)

live["jobs"] = next_jobs
live["updated_at"] = now.isoformat()

tmp = jobs_file.with_suffix(jobs_file.suffix + ".tmp")
tmp.write_text(json.dumps(live, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
os.replace(tmp, jobs_file)
print(f"synced cron jobs: {jobs_file}")
PY
