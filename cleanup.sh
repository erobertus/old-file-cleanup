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
DRY_RUN=false
DRY_RUN_DETAILED=false

# Function to display usage
usage() {
  echo "Usage: $0 [-p directory] [-n days] [-w pattern] [-k] [-l] [-d] [-D] [-z] [-o archive_directory]"
  echo "  -p directory: Directory to clean (default: /var/spool/asterisk/monitor)"
  echo "  -n days: Number of days to consider files old (default: 180)"
  echo "  -w pattern: Wildcard pattern for directories to include (default: *)"
  echo "  -k: Keep empty directories (skip deleting them)"
  echo "  -l: Log to syslog (if not specified, logs to terminal)"
  echo "  -d: Dry run (summarize how many files would be deleted without deleting them)"
  echo "  -D: Detailed dry run (list every file/directory that would be deleted)"
  echo "  -z: Create a compressed tar archive of deleted files"
  echo "  -o archive_directory: Directory to place the archive (default: top of working directory)"
  exit 1
}

# Parse options
CREATE_ARCHIVE=false
ARCHIVE_OUTPUT_DIR=""

while getopts ":p:n:w:kldDzo:" opt; do
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
    d)
      DRY_RUN=true
      ;;
    D)
      DRY_RUN=true
      DRY_RUN_DETAILED=true
      ;;
    z)
      CREATE_ARCHIVE=true
      ;;
    o)
      CREATE_ARCHIVE=true
      ARCHIVE_OUTPUT_DIR=$OPTARG
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

if [ "$CREATE_ARCHIVE" = true ]; then
  if [ -z "$ARCHIVE_OUTPUT_DIR" ]; then
    ARCHIVE_OUTPUT_DIR=$DIRECTORY
  fi

  if [ ! -d "$ARCHIVE_OUTPUT_DIR" ]; then
    if [ "$LOG_TO_SYSLOG" = true ]; then
      logger -p local0.err "Archive directory $ARCHIVE_OUTPUT_DIR does not exist."
    else
      echo "Archive directory $ARCHIVE_OUTPUT_DIR does not exist."
    fi
    exit 1
  fi

  ARCHIVE_NAME="cleanup_deleted_$(date +%Y%m%d%H%M%S)"
  ARCHIVE_WORKING_TAR="$ARCHIVE_OUTPUT_DIR/$ARCHIVE_NAME.tar"
  ARCHIVE_FINAL_PATH="$ARCHIVE_WORKING_TAR.gz"
  ARCHIVE_INITIALIZED=false
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

  if [ "$DRY_RUN" = true ]; then
    FILE_COUNT=0
    while IFS= read -r -d '' FILE; do
      FILE_COUNT=$((FILE_COUNT + 1))
      if [ "$DRY_RUN_DETAILED" = true ]; then
        log_message "Dry run: would delete file: $FILE"
      fi
    done < <(find "$TARGET_DIR" -type f -mtime +$DAYS -print0)

    if [ $FILE_COUNT -eq 0 ]; then
      log_message "Dry run: No files older than $DAYS days found in $TARGET_DIR."
    else
      log_message "Dry run: $FILE_COUNT files would be deleted in $TARGET_DIR."
    fi
  else
    FILES_FOR_DIR=()
    while IFS= read -r -d '' FILE; do
      FILES_FOR_DIR+=("$FILE")
    done < <(find "$TARGET_DIR" -type f -mtime +$DAYS -print0)

    if [ ${#FILES_FOR_DIR[@]} -eq 0 ]; then
      log_message "No files older than $DAYS days found in $TARGET_DIR."
    else
      if [ "$CREATE_ARCHIVE" = true ]; then
        if [ "$ARCHIVE_INITIALIZED" = false ]; then
          TAR_ARGS=(-cf "$ARCHIVE_WORKING_TAR")
          ARCHIVE_INITIALIZED=true
        else
          TAR_ARGS=(-rf "$ARCHIVE_WORKING_TAR")
        fi

        if ! printf '%s\0' "${FILES_FOR_DIR[@]}" | tar "${TAR_ARGS[@]}" --absolute-names --null -T -; then
          log_message "Failed to add files from $TARGET_DIR to archive $ARCHIVE_WORKING_TAR."
        else
          log_message "Added ${#FILES_FOR_DIR[@]} files from $TARGET_DIR to archive."
        fi
      fi

      for FILE in "${FILES_FOR_DIR[@]}"; do
        log_message "Deleting file: $FILE"
        rm -f "$FILE"
      done
    fi
  fi

  if [ "$SKIP_EMPTY_DELETION" = false ]; then
    log_message "Deleting empty directories in $TARGET_DIR..."
    if [ "$DRY_RUN" = true ]; then
      EMPTY_DIR_COUNT=0
      while IFS= read -r -d '' EMPTY_DIR; do
        EMPTY_DIR_COUNT=$((EMPTY_DIR_COUNT + 1))
        if [ "$DRY_RUN_DETAILED" = true ]; then
          log_message "Dry run: would delete empty directory: $EMPTY_DIR"
        fi
      done < <(find "$TARGET_DIR" -type d -empty -print0)

      if [ $EMPTY_DIR_COUNT -eq 0 ]; then
        log_message "Dry run: No empty directories would be removed in $TARGET_DIR."
      else
        log_message "Dry run: $EMPTY_DIR_COUNT empty directories would be removed in $TARGET_DIR."
      fi
    else
      # Find and delete empty directories
      find "$TARGET_DIR" -type d -empty -exec bash -c 'log_message "Deleting empty directory: $1"; rmdir "$1"' _ {} \; -prune
    fi
  else
    log_message "Skipping deletion of empty directories in $TARGET_DIR."
  fi
done

if [ "$CREATE_ARCHIVE" = true ] && [ "$ARCHIVE_INITIALIZED" = true ]; then
  if gzip -f "$ARCHIVE_WORKING_TAR"; then
    log_message "Created archive of deleted files at $ARCHIVE_FINAL_PATH."
  else
    log_message "Failed to compress archive $ARCHIVE_WORKING_TAR."
  fi
elif [ "$CREATE_ARCHIVE" = true ]; then
  log_message "Archive requested but no files were deleted, so no archive was created."
fi

log_message "Cleanup completed for directory: $DIRECTORY"
