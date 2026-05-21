---
name: discord-freeze
description: "Discord timeout/freezing requestを扱う。自然文ではprepare後に明示確認、承認後のみapplyする。"
platforms: [macos, linux]
metadata:
  hermes:
    tags: [discord, moderation, timeout, safety]
    category: discord
---

# Discord Freeze

Discord timeout/freezing requestを扱う。自然文の依頼では即実行しない。

## Server Boundary

Only prepare/apply freezes inside the same Discord server/guild as this Hermes profile.
Do not timeout users in another server, even if the bot token can technically access it.
The helper command enforces `DISCORD_ALLOWED_GUILDS`.

## Trigger

Use this skill when the user asks:

- `/discord-freeze user:@user duration:30m reason:spam`
- `@user を30分凍結して。理由: spam`
- `この人を一時的に発言停止にして`

## Hard Rules

- Never infer a freeze from summary/search results.
- Never freeze without an explicit freeze request.
- Natural language request requires two steps:
  1. prepare action
  2. user replies exactly with approval such as `実行` or `apply`
- Reason is required.
- Duration is required. Default max is 24h unless `DISCORD_FREEZE_MAX_SECONDS` is configured.
- Server owner and administrators are protected.
- If permissions are missing, report the Discord error and do not retry destructively.

## Workflow

1. Resolve target user id and guild id.
   - If the request mentions a user, use the Discord mention id.
   - If only a name is given, use the Discord member search tool when available, otherwise ask for a mention/user id.
2. Prepare:
   ```bash
   ~/.hermes/bin/discord-freeze prepare --guild GUILD_ID --user-id USER_ID --duration 30m --reason "reason" --executor-id EXECUTOR_ID --source-message-id MESSAGE_ID
   ```
3. Show the pending action summary and ask for explicit approval.
4. If the next user message approves the exact action, apply:
   ```bash
   ~/.hermes/bin/discord-freeze apply --action-id ACTION_ID --approval-message-id MESSAGE_ID
   ```
5. Report the result.

## Output

For prepare:

- 対象
- 期間
- 理由
- action_id
- 実行するには「実行」と返信してください

For apply:

- 実行結果
- timeout解除予定時刻
- audit status
