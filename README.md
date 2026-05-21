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

## Deploy

Run this on the subMac after cloning this repo:

```bash
./scripts/deploy.sh
```

To restart LaunchDaemons after deployment:

```bash
RESTART=1 ./scripts/deploy.sh
```

The script does not overwrite `.env`. Create `.env` from each profile's `.env.example` and fill secrets on the machine.

## Secret Check

Before committing:

```bash
./scripts/validate-no-secrets.sh
```

This is a heuristic check. Still review diffs before pushing.
