#!/bin/bash

# Define the script name and its destination directory
SCRIPT_NAME="cleanup.sh"
DESTINATION="/usr/local/bin/$SCRIPT_NAME"

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
