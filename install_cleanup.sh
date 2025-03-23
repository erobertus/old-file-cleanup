#!/bin/bash

SCRIPT_NAME="cleanup.sh"
DESTINATION="/usr/local/bin/$SCRIPT_NAME"
LOG_ROTATE_DIR="/etc/logrotate.d"
LOGFILE=""
USE_SYSLOG=false

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

# Prompt for logging method
echo
echo "Select logging method:"
echo "  1) Log to syslog"
echo "  2) Log to a file"
echo "  3) No logging"
read -p "Enter choice [1-3]: " LOG_CHOICE

case "$LOG_CHOICE" in
  1)
    USE_SYSLOG=true
    CRON_CMD="$DESTINATION -l"
    echo "Logging to syslog will be enabled."
    ;;
  2)
    read -p "Enter full path to log file [default: /var/log/cleanup.log]: " LOGFILE
    LOGFILE=${LOGFILE:-/var/log/cleanup.log}

    CRON_CMD="$DESTINATION >> \"$LOGFILE\" 2>&1"
    echo "Logging to file: $LOGFILE"

    # Configure logrotate
    BASENAME=$(basename "$LOGFILE")
    ROTATE_CONF="$LOG_ROTATE_DIR/cleanup_log_$BASENAME"

    sudo tee "$ROTATE_CONF" > /dev/null <<EOF
$LOGFILE {
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
  3)
    CRON_CMD="$DESTINATION"
    echo "No logging will be configured."
    ;;
  *)
    echo "Invalid selection."
    exit 1
    ;;
esac

# Build final cron line
CRON_JOB="$MINUTE $HOUR * * * $CRON_CMD >/dev/null 2>&1"

# Install the cron job (remove any previous jobs pointing to the script)
( crontab -l 2>/dev/null | grep -v "$DESTINATION"; echo "$CRON_JOB" ) | crontab -

echo
echo "Cron job installed:"
echo "$CRON_JOB"
