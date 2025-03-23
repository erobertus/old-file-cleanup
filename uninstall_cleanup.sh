#!/bin/bash

SCRIPT_NAME="cleanup.sh"
DESTINATION="/usr/local/bin/$SCRIPT_NAME"
LOGROTATE_CONF="/etc/logrotate.d/cleanup_log"

# Remove the script from /usr/local/bin/
if [ -f "$DESTINATION" ]; then
  sudo rm "$DESTINATION"
  if [ $? -ne 0 ]; then
    echo "Failed to remove the script from $DESTINATION."
    exit 1
  else
    echo "Script $SCRIPT_NAME has been successfully removed from $DESTINATION."
  fi
else
  echo "Script $SCRIPT_NAME not found in $DESTINATION."
fi

# Remove the cron job
(crontab -l 2>/dev/null | grep -v "$DESTINATION") | crontab -
if [ $? -ne 0 ]; then
  echo "Failed to remove the cron job."
  exit 1
fi

echo "Cron job for $SCRIPT_NAME has been successfully removed."

# Remove logrotate config if it exists
if [ -f "$LOGROTATE_CONF" ]; then
  sudo rm "$LOGROTATE_CONF"
  if [ $? -ne 0 ]; then
    echo "Failed to remove logrotate configuration at $LOGROTATE_CONF."
    exit 1
  else
    echo "Logrotate configuration $LOGROTATE_CONF has been removed."
  fi
else
  echo "No logrotate configuration found at $LOGROTATE_CONF."
fi
