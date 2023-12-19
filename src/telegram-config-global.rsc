#!rsc by ShellHacks
# RouterOS script: telegram-config-global
# Copyright (c) 2011-2024 www.ShellHacks.com <mail@shellhacks.com>
#
# Telegram Bot API global settings
# Documentation: https://www.shellhacks.com/mikrotik-send-message-to-telegram
# Source: https://github.com/shellhacks/MikroTik/blob/main/src/telegram-config-global.rsc
#
# Tested on RouterOS, version=7.12 (stable)
# Version: 1.0.0

# BEGIN SETUP
:global tgBotToken "0123456789:ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghi"
:global tgChatID "012345678"
# END SETUP

# Send message to Telegram
# Usage: $tgSendMessage $tgChatID "<message>"
:global tgSendMessage do={
  :global tgBotToken
  :local url ("https://api.telegram.org/bot$tgBotToken" . "/sendMessage\?chat_id=" . $1 . "&text=" . $2 . "&parse_mode=html")
  /tool fetch keep-result=no url="$url"
}