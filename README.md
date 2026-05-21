# nikechan-hermes-runtime

AIニケちゃんのHermes Agent差分だけを管理するためのリポジトリ雛形。

Hermes本体、bundled skills、標準Gateway実装、state DB、logs、sessions、auth cacheは管理対象外です。
このrepoはサブMac上のHermes profileへ、ニケちゃん固有の設定・人格・記憶・追加スキル・補助CLIだけを再配置します。

## Managed Files

- `bin/`
  - `discord-history`
  - `discord-freeze`
  - `nikechan-emotion`
- `profiles/<profile>/config.yaml`
- `profiles/<profile>/SOUL.md`
- `profiles/<profile>/memories/*.md`
- `profiles/<profile>/skills/*/SKILL.md`
- `profiles/<profile>/plugins/nikechan-discord-routing/`
- `profiles/<profile>/.env.example`

## Not Managed

- `.env` actual files
- Discord bot tokens
- Alibaba/DashScope API keys
- `auth.json`
- `state.db`
- `sessions/`
- `logs/`
- Hermes bundled runtime under `~/.hermes/hermes-agent`

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

## Live Management

Hermes reads files from `~/.hermes`, but the managed files should be symlinked
back to this repo. That makes this repo the live source of truth: editing a
managed skill/config/persona file in this repo changes what Hermes reads after
the gateway restarts.

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

## Secret Check

Before committing:

```bash
./scripts/validate-no-secrets.sh
```

This is a heuristic check. Still review diffs before pushing.
