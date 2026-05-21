---
name: discord-reminder
description: "自然文からHermes cron reminderを作る。固定文通知とagentic reminderを使い分ける。"
platforms: [macos, linux]
metadata:
  hermes:
    tags: [discord, reminder, cron]
    category: discord
---

# Discord Reminder

自然文からstaticまたはagenticなHermes cron reminderを作る。

## Trigger

Use this skill when the user asks for reminders or scheduled Discord posts:

- `/discord-reminder 明日の10時に #ops にリリース確認を通知`
- `毎週月曜9時に週次MTGの準備を通知して`
- `毎朝9時に昨日の #dev の重要決定だけまとめて投稿して`

## Rules

- Extract schedule, timezone, destination, and reminder text.
- Use the current Discord channel as destination if the user does not specify one.
- Static reminder: fixed text only. Prefer no-agent cron when Hermes supports it.
- Agentic reminder: needs Discord context, search, summary, or judgement at run time. Use agent mode.
- Do not create recursive reminders that create more reminders unless the user explicitly confirms.
- Do not schedule moderation actions such as freeze/timeouts.
- If the destination is a public channel and the reminder is agentic, confirm the schedule and behavior before creating it unless the user used an explicit slash command with all fields.

## Workflow

1. Normalize the requested time. If ambiguous, ask one concise clarification.
2. Prefer Hermes cron:
   ```bash
   hermes cron --help
   hermes cron create ...
   ```
   Use the profile currently serving the Discord channel.
3. If the reminder is a daily/weekly summary, preload `discord-summary` in the job prompt and specify the exact channel and range logic.
4. After creating the cron job, reply with:
   - schedule
   - timezone
   - destination
   - static/agentic mode
   - job id/name if available

## Output

Keep the confirmation short and practical.
