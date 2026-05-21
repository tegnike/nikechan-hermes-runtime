# nikechan-hermes-runtime

AIニケちゃんの Hermes Agent runtime について、ニケちゃん固有の差分だけを管理するリポジトリです。

Hermes本体、bundled skills、標準Gateway実装、状態DB、ログ、セッション、認証キャッシュは管理対象外です。
このrepoでは、サブMac上のHermes profileに適用する設定、人格、記憶、独自スキル、補助CLIだけを管理します。

## 管理対象

- `bin/`
  - `discord-history`
  - `discord-freeze`
  - `discord-amnesty`
  - `discord-autofreeze`
  - `nikechan-emotion`
  - `gemini-audio-analyze`
- `hermes-scripts/`
  - live `~/.hermes/scripts` へリンクするスクリプト群
- `profiles/<profile>/config.yaml`
- `profiles/<profile>/profile.yaml`
- `profiles/<profile>/SOUL.md`
- `profiles/<profile>/memories/*.md`
- `profiles/<profile>/scripts/`
- `profiles/<profile>/cron/jobs.json`
- `profiles/<profile>/skills/`
- `profiles/<profile>/plugins/`
- `profiles/<profile>/.env.example`

## 管理しないもの

- 実際の `.env`
- Discord bot token
- Alibaba/DashScope API key
- Google Gemini API key
- `auth.json`
- `state.db`
- `sessions/`
- `logs/`
- `gateway/`
- `gateway_state.json`
- Discord slash command同期状態
- cron lock files
- `channel_directory.json`
- profile-localの `bin/tirith` runtime binary
- profile `workspace/` の内容
- Hermes bundled runtime under `~/.hermes/hermes-agent`

`cron/jobs.json` はスケジュール定義と実行状態を兼ねています。
Hermesがlive scheduler configとして読むため管理対象にしていますが、cron実行後に `next_run_at`、`last_run_at`、実行回数、エラー状態などがdirtyになります。

## プロファイル

### `nikechandiscord`

- AIニケちゃんサーバー用
- home/allowed channel: `1404724174890602496` (`#aiニケちゃんbot`)
- allowed guild: `1404689195150217217`

### `nikechanmain`

- 既存ニケサーバー用
- home/allowed channel: `1181160629063655484`
- allowed guild: `1090678630704762992`

両profileの基本モデル設定:

```yaml
model:
  default: qwen3.6-plus
  provider: alibaba-coding-plan
```

## 公開Discord向けの安全設定

公開Discordのgateway sessionでは、通常チャットから危険なツールを使えないようにしています。

- `platform_toolsets.discord: []`
- `agent.disabled_toolsets` で terminal、file、skill管理、memory、cron、delegation、Discord admin などを無効化

これにより、Discord上の一般ユーザーはAIニケちゃんと会話できますが、設定変更、スキル作成、シェル実行、記憶変更、Discord管理操作はできません。
runtime変更はサブMac上のこのrepoから行います。

## 自律モデレーション

モデレーションtimeoutはユーザーコマンドでは動きません。

- `discord-freeze`: timeoutのprepare/applyを行う低レベルヘルパー
- `discord-autofreeze`: cron専用の自律判定

`discord-autofreeze` は、短時間大量投稿、同一文面連投、大量メンション、外部連絡先つき案件勧誘などの客観シグナルだけを対象にします。
標準timeoutは12時間です。

管理者が具体的な謝罪文を共有した場合のみ、`discord-amnesty` がtimeoutの短縮または解除を判断できます。
実行前にDiscord上の投稿者権限を確認するため、一般ユーザー本人からの解除依頼では動きません。

## 音楽・音声解析

音楽・音声解析は `music-audio-analysis` と `gemini-audio-analyze` で扱います。

Discord上で音楽・音声解析の依頼があり、添付音声ファイル、公開Suno URL、直接メディアURLのいずれかがある場合、Gemini APIで解析します。

## live反映

Hermesはlive pathとして `~/.hermes` を読みます。
ただし独自スキルは、`config.yaml` の `skills.external_dirs` でこのrepoの `profiles/<profile>/skills` を直接読ませます。
これによりHermes bundled skillsをgit管理せず、ニケちゃん固有スキルだけをこのrepoで管理できます。

liveの `~/.hermes/profiles/<profile>/skills` ディレクトリを丸ごとこのrepoへsymlinkしないでください。
Hermesがbundled/runtime skillsをそこへ展開することがあり、repoがHermes管理ライブラリで汚れます。

初回セットアップまたはリンク確認:

```bash
./scripts/link-live.sh
```

設定変更後にgatewayも再起動する場合:

```bash
RESTART=1 ./scripts/link-live.sh
```

`link-live.sh` は `.env` を上書きしません。
`.env` は各profileの `.env.example` から作成し、サブMac上でだけ秘密情報を設定します。

live symlinkとgit差分の確認:

```bash
./scripts/status-live.sh
```

`scripts/deploy.sh` は互換用のaliasとして残しており、実体は `scripts/link-live.sh` です。

## 編集手順

管理対象ファイルはサブMac上のrepoで編集します。

```bash
cd /Users/nikenike/WorkSpace/nikechan-hermes-runtime
```

config、SOUL、memories、scripts、bin、pluginsはlive pathへsymlinkされています。
独自skillsは `skills.external_dirs` 経由でrepoから直接読まれるため、新しいスキル名をdeploy用allowlistへ追加する必要はありません。

新規スキル作成:

```bash
./scripts/new-skill.sh nikechandiscord my-skill
```

live profile側に直接作られたスキルをrepoへ取り込む場合:

```bash
./scripts/adopt-live-skill.sh nikechandiscord my-skill
```

コミット前にはsecret checkを実行します。

```bash
./scripts/validate-no-secrets.sh
git status
git add profiles/nikechandiscord/skills/my-skill
git commit -m "Add my skill"
```

pushは明示的に指示された場合だけ行います。

## secret check

```bash
./scripts/validate-no-secrets.sh
```

これはヒューリスティックな検査です。
commit前には必ずdiffも目視確認してください。
