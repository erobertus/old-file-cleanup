#!/bin/bash

# Define the source script and the destination directory
SCRIPT_NAME="cleanup.sh"
DESTINATION="/usr/local/bin/$SCRIPT_NAME"

# Check if the script exists in the current directory
if [ ! -f "$SCRIPT_NAME" ]; then
  echo "Script $SCRIPT_NAME not found in the current directory."
  exit 1
fi

# Copy the script to /usr/local/bin/
sudo cp "$SCRIPT_NAME" "$DESTINATION"
if [ $? -ne 0 ]; then
  echo "Failed to copy the script to $DESTINATION."
  exit 1
fi

# Make the script executable
sudo chmod +x "$DESTINATION"
if [ $? -ne 0 ]; then
  echo "Failed to make the script executable."
  exit 1
fi

echo "Script $SCRIPT_NAME has been successfully copied to $DESTINATION."

# Ask the user for the time to schedule the cron job
read -p "Enter the hour (0-23) at which you want to run the script: " HOUR
read -p "Enter the minute (0-59) at which you want to run the script: " MINUTE

# Validate the input
if ! [[ "$HOUR" =~ ^[0-9]+$ ]] || [ "$HOUR" -lt 0 ] || [ "$HOUR" -gt 23 ]; then
  echo "Invalid hour: $HOUR. Please enter a value between 0 and 23."
  exit 1
fi

if ! [[ "$MINUTE" =~ ^[0-9]+$ ]] || [ "$MINUTE" -lt 0 ] || [ "$MINUTE" -gt 59 ]; then
  echo "Invalid minute: $MINUTE. Please enter a value between 0 and 59."
  exit 1
fi

# Add the cron job with output redirected to /dev/null
(crontab -l 2>/dev/null; echo "$MINUTE $HOUR * * * $DESTINATION -l >/dev/null 2>&1") | crontab -
if [ $? -ne 0 ]; then
  echo "Failed to add the cron job."
  exit 1
fi

echo "Cron job has been added to run $SCRIPT_NAME at $HOUR:$MINUTE every day with logging to syslog and output redirected to /dev/null."
