# nikechan-hermes-runtime

AIニケちゃんのHermes Agent差分だけを管理するためのリポジトリ雛形。

Hermes本体、bundled skills、標準Gateway実装、state DB、logs、sessions、auth cacheは管理対象外です。
このrepoはサブMac上のHermes profileへ、ニケちゃん固有の設定・人格・記憶・追加スキル・補助CLIだけを再配置します。

## Managed Files

- `bin/`
  - `discord-history`
  - `discord-freeze`
  - `discord-amnesty`
  - `discord-autofreeze`
  - `nikechan-emotion`
  - `gemini-audio-analyze`
- `hermes-scripts/`
  - scripts linked to `~/.hermes/scripts`
- `profiles/<profile>/config.yaml`
- `profiles/<profile>/profile.yaml`
- `profiles/<profile>/SOUL.md`
- `profiles/<profile>/memories/*.md`
- `profiles/<profile>/scripts/` when present
- `profiles/<profile>/cron/jobs.json` when present
- `profiles/<profile>/skills/`
- `profiles/<profile>/plugins/`
- `profiles/<profile>/.env.example`

## Not Managed

- `.env` actual files
- Discord bot tokens
- Alibaba/DashScope API keys
- Google Gemini API keys
- `auth.json`
- `state.db`
- `sessions/`
- `logs/`
- `gateway/`, `gateway_state.json`, command sync state, and cron lock files
- `channel_directory.json`; channel lists are fetched from Discord at runtime
- profile-local `bin/tirith` runtime binaries
- profile `workspace/` contents, except files intentionally copied into this repo
- Hermes bundled runtime under `~/.hermes/hermes-agent`

`cron/jobs.json` currently contains both schedule definitions and mutable run
state (`next_run_at`, `last_run_at`, counters, errors). It is managed because
Hermes uses it as the live scheduler config, but it may become dirty after cron
ticks.

## Profiles

- `nikechandiscord`
  - AIニケちゃんサーバー用
  - Home/allowed channel: `1404724174890602496` (`#aiニケちゃんbot`)
  - Allowed guild: `1404689195150217217`
- `nikechanmain`
  - 既存ニケサーバー用
  - Home/allowed channel: `1181160629063655484`
  - Allowed guild: `1090678630704762992`

Both profiles currently use:

```yaml
model:
  default: qwen3.6-plus
  provider: alibaba-coding-plan
```

Discord gateway sessions are intentionally locked down for public channel use:

- `platform_toolsets.discord: []`
- `agent.disabled_toolsets` disables terminal, file, skill management, memory,
  cron, delegation, Discord admin, and other tool-capable surfaces.

This means unknown Discord users can chat with AI Nikechan in the allowed
channel, but they cannot use the bot to edit config, create skills, run shell
commands, mutate memory, or administer Discord. Runtime changes are managed from
this repo on the subMac.

Moderation timeouts are also not user-command driven. `discord-freeze` is the
low-level prepare/apply helper, while `discord-autofreeze` is the cron-only
autonomous checker. It only acts on spam signals such as message floods,
duplicate repeats, excessive mentions, and unsolicited external-contact
business solicitation inside the allowed guild. The default timeout duration is
12 hours. Admin-only amnesty requests can shorten or release a timeout when a moderator shares a concrete apology; requester permissions are checked against Discord before any action is applied.

Music/audio analysis is routed through `music-audio-analysis` and `gemini-audio-analyze`. In Discord, requests mentioning music/audio analysis are handled before generic Discord history search; with an attached audio file, public Suno song URL, or direct media URL, the helper runs Gemini audio analysis.

## Live Management

Hermes reads files from `~/.hermes`, but config points `skills.external_dirs`
at this repo's `profiles/<profile>/skills`. That makes this repo the source of
truth for Nikechan custom skills without git-managing Hermes bundled skills.
Editing a custom skill in this repo changes what Hermes reads after the gateway
restarts.

Do not symlink the whole live `~/.hermes/profiles/<profile>/skills` directory
to this repo. Hermes may populate bundled/runtime skills there, and linking the
whole directory pollutes the repo with Hermes-managed libraries.

Run this on the subMac after cloning this repo:

```bash
./scripts/link-live.sh
```

To restart LaunchDaemons after linking or editing config:

```bash
RESTART=1 ./scripts/link-live.sh
```

The script does not overwrite `.env`. Create `.env` from each profile's `.env.example` and fill secrets on the machine.

To verify live symlinks and see pending git changes:

```bash
./scripts/status-live.sh
```

`scripts/deploy.sh` is kept as a compatibility alias for `scripts/link-live.sh`.

## Editing Workflow

For managed files, edit the repo on the subMac:

```bash
cd /Users/nikenike/WorkSpace/nikechan-hermes-runtime
```

Config/persona/memory files are live symlinks. Custom skills are read directly
from the repo through `skills.external_dirs`, so new skill names do not need to
be added to a deployment allowlist.

Create a new git-managed skill with:

```bash
./scripts/new-skill.sh nikechandiscord my-skill
```

If an operator creates a skill directly under the live profile skills directory,
adopt it into git with:

```bash
./scripts/adopt-live-skill.sh nikechandiscord my-skill
```

Then commit and push:

```bash
./scripts/validate-no-secrets.sh
git status
git add profiles/nikechandiscord/skills/my-skill
git commit -m "Add my skill"
git push
```

## Secret Check

Before committing:

```bash
./scripts/validate-no-secrets.sh
```

This is a heuristic check. Still review diffs before pushing.
