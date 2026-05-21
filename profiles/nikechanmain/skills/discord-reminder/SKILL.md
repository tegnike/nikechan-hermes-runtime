---
name: discord-reminder
description: "公開Discordから安全に固定文リマインダーを登録する。通常チャットにはcron/file/terminal権限を開放しない。"
platforms: [macos, linux]
metadata:
  hermes:
    tags: [discord, reminder]
    category: discord
---

# Discord Reminder

公開Discordでの自然文リマインダー登録を扱う。

## Trigger

Use this skill when the user asks for a reminder or scheduled fixed Discord notification:

- `10分後に休憩って言って`
- `明日10時にリリース確認を通知して`
- `毎日9時に朝会の準備をリマインドして`
- `毎週月曜9時に週次確認を通知して`

## Public Discord Behavior

- 通常のDiscord応答からHermes cron、terminal、file toolは使わない。
- ルーティングプラグインが `~/.hermes/bin/discord-reminder create` だけを呼び、ローカル状態へ登録する。
- 配信は1分ごとの `discord-reminder-dispatcher` no-agent cronが行う。
- 各リマインダーはHermes cronジョブとして増やさない。
- 通知先は、明示された `<#channel>` または依頼元チャンネル。
- 短い間隔の定期実行は作成しない。定期リマインダーは毎日・毎週のみ。
- `@everyone`、ロールメンション、凍結/timeout/ban/kick/mute/削除などのモデレーション操作は拒否する。

## Output

登録結果を短く返す。

- 通知予定
- 通知先
- 本文
- 作成できなかった場合は理由
