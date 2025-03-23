#!/bin/bash

SCRIPT_NAME="cleanup.sh"
DESTINATION="/usr/local/bin/$SCRIPT_NAME"
LOG_ROTATE_DIR="/etc/logrotate.d"

# Check for source script
if [ ! -f "$SCRIPT_NAME" ]; then
  echo "Script '$SCRIPT_NAME' not found in the current directory."
  exit 1
fi

# Check for crontab availability
if ! command -v crontab >/dev/null 2>&1; then
  echo "'crontab' command not found. Please install cron before running this script."
  exit 1
fi

# Install the script
echo "Installing script to '$DESTINATION'..."
sudo cp "$SCRIPT_NAME" "$DESTINATION" || {
  echo "Failed to copy the script."
  exit 1
}

sudo chmod +x "$DESTINATION" || {
  echo "Failed to make the script executable."
  exit 1
}

echo "Script installed successfully."

# Prompt for schedule
read -p "Enter the hour (0–23) to run the script daily: " HOUR
read -p "Enter the minute (0–59) to run the script daily: " MINUTE

if ! [[ "$HOUR" =~ ^[0-9]+$ ]] || [ "$HOUR" -lt 0 ] || [ "$HOUR" -gt 23 ]; then
  echo "Invalid hour: $HOUR"
  exit 1
fi

if ! [[ "$MINUTE" =~ ^[0-9]+$ ]] || [ "$MINUTE" -lt 0 ] || [ "$MINUTE" -gt 59 ]; then
  echo "Invalid minute: $MINUTE"
  exit 1
fi

# Ask for preferred logging method
echo
echo "Select logging method:"
echo "  1) Syslog (cleanup.sh will use -l, cron output redirected to /dev/null)"
echo "  2) Terminal (cron output redirected to $DEFAULT_LOGFILE)"
read -p "Enter choice [1-2]: " LOG_CHOICE

case "$LOG_CHOICE" in
  1)
    CRON_CMD="$DESTINATION -l"
    CRON_SUFFIX=">/dev/null 2>&1"
    echo "Logging to syslog enabled."
    ;;
  2)
    CRON_CMD="$DESTINATION"
    CRON_SUFFIX=">> $DEFAULT_LOGFILE 2>&1"
    echo "Logging to $DEFAULT_LOGFILE enabled."

    # Configure logrotate
    ROTATE_CONF="$LOG_ROTATE_DIR/cleanup_log"
    sudo tee "$ROTATE_CONF" > /dev/null <<EOF
$DEFAULT_LOGFILE {
    daily
    rotate 14
    compress
    missingok
    notifempty
    create 0644 root root
}
EOF

    echo "Logrotate configuration created at: $ROTATE_CONF"
    ;;
  *)
    echo "Invalid selection."
    exit 1
    ;;
esac

# Final cron job
CRON_JOB="$MINUTE $HOUR * * * $CRON_CMD $CRON_SUFFIX"

# Install the cron job (removes old jobs pointing to the same script)
( crontab -l 2>/dev/null | grep -v "$DESTINATION"; echo "$CRON_JOB" ) | crontab -

echo
echo "Cron job installed:"
echo "$CRON_JOB"
