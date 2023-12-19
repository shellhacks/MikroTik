#!rsc by ShellHacks
# RouterOS script: auth-logs-monitoring
# Copyright (c) 2011-2024 www.ShellHacks.com <mail@shellhacks.com>
#
# Monitor authentication events and send notifications on login attempts to Telegram
# Documentation: https://www.shellhacks.com/mikrotik-telegram-notification-on-login-attempt
# Source: https://github.com/shellhacks/MikroTik/blob/main/src/auth-logs-monitoring.rsc
#
# Requires:
# - telegram-config-global
#   https://github.com/shellhacks/MikroTik/blob/main/src/telegram-config-global.rsc
#
# Tested on RouterOS, version=7.12 (stable)
# Version: 1.0.0

# tgSendMessage is set by tgSetEnvironment script which runs at startup by the scheduler,
# contains Telegram BotAPI string for sendMessage method.

# BEGIN SETUP
# Set by 'telegram-config-global' script which runs on startup using a scheduler
# and contains Telegram Bot API settings / connection string
:global tgSendMessage
:global tgChatID
# Log IDs to parse through
:local logIDs [/log find where buffer=auth]
# END SETUP

# Used to track already shown log entries
:global lastLogID

:local skip
:local buffer ""

# Check if last ID is not set and trigger the skip flag
:if ([:typeof $lastLogID]="nothing") do={
    :set buffer ("&#129335;&#8205;&#9794;&#65039; Last log ID is not found. The router may have rebooted.%0A&#9200; Uptime: ".[/system resource get uptime])
    :set skip true
  } else={
    :set skip true
  }

# Run through the log buffer and parse entries
:foreach logID in=$logIDs do={

  :if ($skip = false) do={
    :local logTopics [/log get $logID topics]
    :local logTime [/log get $logID time]
    :local logMessage [/log get $logID message]

    ## Critical error events
    :if ($logTopics="system;error;critical") do={
      :set buffer ($buffer.$logTime." &#9888;&#65039; ".$logMessage."%0A")
    }

    ## Logins to the router
    :if ($logTopics="system;info;account" && $logMessage~"logged in") do={
      :set buffer ($buffer.$logTime." &#128275; ".$logMessage."%0A")
    }

    # Logouts from the router
    :if ($logTopics="system;info;account" && $logMessage~"logged out") do={
      :set buffer ($buffer.$logTime." &#128274; ".$logMessage."%0A")
    }
  }

  # Have reached an unshown logMessage, so don't skip then
  :if ($logID=$lastLogID) do={ :set skip false }
}

# Remember last log ID
:set lastLogID [:pick $logIDs ([:len $logIDs]-1)]

# Consider the buffer for sending out only if it isn't empty
:if ($buffer!="") do={
  :local message ""
  
  # Replace URL-unsafe characters with ASCII (UTF-8)
  :for i from=0 to=([:len $buffer]-1) do={
    :local char [:pick $buffer $i]
    :if ($char="&") do={ :set char "%26" }
    :if ($char="\$") do={ :set char "%24" }
    :if ($char="+") do={ :set char "%2B" }
    :if ($char=",") do={ :set char "%2C" }
    :if ($char="/") do={ :set char "%2F" }
    :if ($char=":") do={ :set char "%3A" }
    :if ($char=";") do={ :set char "%3B" }
    :if ($char="=") do={ :set char "%3D" }
    :if ($char="?") do={ :set char "%3F" }
    :if ($char="@") do={ :set char "%40" }
    :if ($char="#") do={ :set char "%23" }
    :if ($char=" ") do={ :set char "%20" }
    :if ($char="<") do={ :set char "%3C" }
    :if ($char=">") do={ :set char "%3E" }
    :if ($char="[") do={ :set char "%5B" }
    :if ($char="]") do={ :set char "%5D" }
    :if ($char="{") do={ :set char "%7B" }
    :if ($char="}") do={ :set char "%7D" }
    :if ($char="|") do={ :set char "%7C" }
    :if ($char="\\") do={ :set char "%5C" }
    :if ($char="^") do={ :set char "%5E" }
    :if ($char="\"") do={ :set char "%22" }
    :set message ($message . $char)
  }
  
  # The maximum length of a Telegram message is 4096 characters
  # Split into several messages if the data to send is > 4096 characters
  :if (([:len $message]-1) < 4096) do={
    $tgSendMessage $tgChatID $message
  } else={
    :for i from=0 to=([:len $message]-1) step=4096 do={
      $tgSendMessage $tgChatID [:pick $message $i ($i+4096)]
      :set i ($i+4096)
    }
  }
}