#!/bin/bash

# Default values
DEFAULT_DIRECTORY="/var/spool/asterisk/monitor"
DEFAULT_DAYS=180
LOG_TO_SYSLOG=false

# Assign default values to variables
DIRECTORY=$DEFAULT_DIRECTORY
DAYS=$DEFAULT_DAYS

# Function to display usage
usage() {
  echo "Usage: $0 [-p directory] [-n days] [-l]"
  echo "  -p directory: Directory to clean (default: /var/spool/asterisk/monitor)"
  echo "  -n days: Number of days to consider files old (default: 180)"
  echo "  -l: Log to syslog (if not specified, logs to terminal)"
  exit 1
}

# Parse options
while getopts ":p:n:l" opt; do
  case ${opt} in
    p)
      DIRECTORY=$OPTARG
      ;;
    n)
      DAYS=$OPTARG
      ;;
    l)
      LOG_TO_SYSLOG=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      ;;
  esac
done

# Check if the directory exists
if [ ! -d "$DIRECTORY" ]; then
  if [ "$LOG_TO_SYSLOG" = true ]; then
    logger -p local0.err "Directory $DIRECTORY does not exist."
  else
    echo "Directory $DIRECTORY does not exist."
  fi
  exit 1
fi

log_message() {
  local message=$1
  if [ "$LOG_TO_SYSLOG" = true ]; then
    echo "$message" | tee >(logger -p local0.info)
  else
    echo "$message"
  fi
}

if [ "$LOG_TO_SYSLOG" = true ]; then
  log_message "Logging to syslog."
else
  log_message "Logging to terminal."
fi

log_message "Starting cleanup of directory: $DIRECTORY"
log_message "Deleting files older than $DAYS days..."

# Find and delete files older than the specified number of days
find "$DIRECTORY" -type f -mtime +$DAYS -exec sh -c 'log_message "Deleting file: $1"' _ {} \; -exec rm -f {} \;

log_message "Deleting empty directories..."

# Find and delete empty directories
find "$DIRECTORY" -type d -empty -exec sh -c 'log_message "Deleting empty directory: $1"' _ {} \; -delete

log_message "Cleanup completed for directory: $DIRECTORY"