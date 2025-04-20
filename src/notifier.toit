// Copyright (C) 2025 Florian Loitsch <florian@loitsch.com>
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import simple-config show Config
import telegram

CONFIG-SCHEMA ::= {
  "title": "Bell",
  "description": "Configuration for the door-bell.",
  "type": "object",
  "properties": {
    "bot-token": {
      "title": "Telegram Bot Token",
      "type": "string",
      "format": "password",
      "description": "The token of the Telegram bot."
    },
    "bot-password": {
      "title": "Telegram Bot Password",
      "type": "string",
      "format": "password",
      "description": "The password of the Telegram bot."
    },
    "chat-ids": {
      "title": "Telegram Chat IDs",
      "type": "array",
      "items": {
        "title": "Chat ID",
        "type": "integer",
      },
      "description": "The chat IDs of the Telegram bot."
    }
  }
}

class Notifier:
  config_/Config? := null
  telegram-task_/Task? := null
  client_/telegram.Client? := null

  start:
    if config_: throw "Already started"
    config_ = Config "flash:florian.loitsch.com/bell/config" --schema=CONFIG-SCHEMA
    config_.serve --port=80
    print config_.values
    start_

  notify:
    if not client_:
      print "Not started"
      return
    chat-ids_.do: | chat-id/int |
      client_.send-message "Ding Dong" --chat-id=chat-id

  close:
    if config_:
      config_.close
    if telegram-task_:
      telegram-task_.cancel

  chat-ids_ -> List:
    if not config_: throw "Not started"
    result := config_.values.get "chat-ids"
    return result or []

  bot-token_ -> string:
    if not config_: throw "Not started"
    return config_.values.get "bot-token"

  bot-password_ -> string:
    if not config_: throw "Not started"
    return config_.values.get "bot-password"

  start_:
    task::
      current-token := bot-token_
      current-password := bot-password_
      print "Current values: $current-token $current-password"
      while true:
        if not telegram-task_ and current-token and current-password:
          telegram-task_ = task:: start-telegram_ --token=current-token --password=current-password
        config_.updated.wait
        new-token := bot-token_
        new-password := bot-password_
        print "New values: $new-token $new-password"
        if current-token != new-token or current-password != new-password:
          if telegram-task_:
            telegram-task_.cancel
            telegram-task_ = null
          current-token = new-token
          current-password = new-password

  start-telegram_ --token/string --password -> none:
    try:
      client_ = telegram.Client --token=token
      client_.listen: | update/telegram.Update |
        if update is not telegram.UpdateMessage: continue.listen

        message := update as telegram.UpdateMessage
        text := message.message.text
        if text == password:
          print "Password is correct"
          chat-id := message.message.chat.id
          client_.send-message "OK" --chat-id=chat-id
          add-chat-id_ chat-id
    finally:
      if client_:
        client_.close
        client_ = null

  add-chat-id_ id/int:
    new-ids := chat-ids_ + [id]
    old-values := config_.values
    values := old-values.copy
    values["chat-ids"] = new-ids
    config_.update values
    print "Added chat id: $id"
