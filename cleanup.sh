#!/bin/bash

# Default values
DEFAULT_DIRECTORY="/var/spool/asterisk/monitor"
DEFAULT_DAYS=180
DEFAULT_PATTERN="*"
LOG_TO_SYSLOG=false

# Assign default values to variables
DIRECTORY=$DEFAULT_DIRECTORY
DAYS=$DEFAULT_DAYS
DIRECTORY_PATTERN=$DEFAULT_PATTERN
SKIP_EMPTY_DELETION=false

# Function to display usage
usage() {
  echo "Usage: $0 [-p directory] [-n days] [-w pattern] [-k] [-l]"
  echo "  -p directory: Directory to clean (default: /var/spool/asterisk/monitor)"
  echo "  -n days: Number of days to consider files old (default: 180)"
  echo "  -w pattern: Wildcard pattern for directories to include (default: *)"
  echo "  -k: Keep empty directories (skip deleting them)"
  echo "  -l: Log to syslog (if not specified, logs to terminal)"
  exit 1
}

# Parse options
while getopts ":p:n:w:kl" opt; do
  case ${opt} in
    p)
      DIRECTORY=$OPTARG
      ;;
    n)
      DAYS=$OPTARG
      ;;
    w)
      DIRECTORY_PATTERN=$OPTARG
      ;;
    k)
      SKIP_EMPTY_DELETION=true
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

# Define the log_message function
log_message() {
  local message=$1
  if [ "$LOG_TO_SYSLOG" = true ]; then
    logger -p local0.info "$message"
  fi
  echo "$message"
}

# Export the log_message function so it can be used in subshells
export -f log_message
export LOG_TO_SYSLOG

if [ "$LOG_TO_SYSLOG" = true ]; then
  log_message "Logging to syslog."
else
  log_message "Logging to terminal."
fi

log_message "Starting cleanup of directory: $DIRECTORY"
if [ "$DIRECTORY_PATTERN" = "*" ]; then
  DIRECTORIES_TO_CLEAN=("$DIRECTORY")
else
  mapfile -t DIRECTORIES_TO_CLEAN < <(find "$DIRECTORY" -type d -name "$DIRECTORY_PATTERN")
  if [ ${#DIRECTORIES_TO_CLEAN[@]} -eq 0 ]; then
    log_message "No directories matching pattern '$DIRECTORY_PATTERN' were found under $DIRECTORY."
    exit 0
  fi
fi

for TARGET_DIR in "${DIRECTORIES_TO_CLEAN[@]}"; do
  log_message "Deleting files older than $DAYS days in $TARGET_DIR..."
  # Find and delete files older than the specified number of days
  find "$TARGET_DIR" -type f -mtime +$DAYS -exec bash -c 'log_message "Deleting file: $1"; rm -f "$1"' _ {} \;

  if [ "$SKIP_EMPTY_DELETION" = false ]; then
    log_message "Deleting empty directories in $TARGET_DIR..."
    # Find and delete empty directories
    find "$TARGET_DIR" -type d -empty -exec bash -c 'log_message "Deleting empty directory: $1"; rmdir "$1"' _ {} \; -prune
  else
    log_message "Skipping deletion of empty directories in $TARGET_DIR."
  fi
done

log_message "Cleanup completed for directory: $DIRECTORY"
