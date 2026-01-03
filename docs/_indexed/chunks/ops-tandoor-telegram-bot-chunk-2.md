---
doc_id: ops/tandoor/telegram-bot
chunk_id: ops/tandoor/telegram-bot#chunk-2
heading_path: ["Telegram Bot", "Shopping Bot"]
chunk_type: prose
tokens: 289
summary: "Shopping Bot"
---

## Shopping Bot
The shopping bot will add any message you send it to your latest open shopping list.

To get a shopping bot follow these steps

1. Create a new Telegram Bot using the [BotFather](https://t.me/botfather)
   - If you want to use the bot with multiple persons add the bot to a group and grant it admin privileges
2. Open the Admin Page (click your username, then admin) and select `Telegram Bots`
3. Create a new Bot
   - token: the token obtained in step one 
   - space: your space (usually Default)
   - user: to the user the bot is meant for (determines the shopping list used)
   - chat id: if you know where messages will be sent from enter the chat ID, otherwise it is set to the first chat the bot received a message from
4. Visit your installation at `recipes.mydomin.tld/telegram/setup/<botid>` with botid being the ID of the bot you just created
   You should see the following message:
    ```json
    {
        "hook_url": "https://recipes.mydomin.tld/telegram/hook/c0c08de9-5e1e-4480-8312-3e256af61340/",
        "create_response": {
            "ok": true,
            "result": true,
            "description": "Webhook was set"
        },
        "info_response": {
            "ok": true,
            "result": {
                "url": "recipes.mydomin.tld/telegram/hook/<webhook_token>",
                "has_custom_certificate": false,
                "pending_update_count": 0,
                "max_connections": 40,
                "ip_address": "46.4.105.116"
            }
        }
    }
    ```

You should now be able to send messages to the bot and have the entries appear in your latest shopping list.

### Resetting
To reset a bot open `recipes.mydomin.tld/telegram/remove/<botid>`
