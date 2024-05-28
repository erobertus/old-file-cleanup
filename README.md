# Cleanup Script

## Purpose

The `cleanup.sh` script is designed to clean up files and directories within a specified directory. It recursively deletes files older than a specified number of days and removes any empty directories. This script can be scheduled to run automatically using cron jobs.

## Features

- Deletes files older than a specified number of days.
- Removes empty directories.
- Can log actions to syslog.
- Configurable through command-line options.
- Install and uninstall scripts for easy setup and removal.

## Usage

### Script Usage

```bash
cleanup.sh [-p directory] [-n days] [-l]
```

- `-p directory`: The directory to clean (default: `/var/spool/asterisk/monitor`).
- `-n days`: Number of days to consider files old (default: `180`).
- `-l`: Log actions to syslog (if not specified, logs to terminal).

### Examples

Using default values:
```bash
./cleanup.sh
```

Specifying custom values:
```bash
./cleanup.sh -p /path/to/directory -n 30
```

Logging actions to syslog:
```bash
./cleanup.sh -l
```

## Installation

Use the provided `install_cleanup.sh` script to install `cleanup.sh` and set up a cron job.

### Installation Script

```bash
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
```

### Running the Installation Script

1. Save the installation script to a file, for example, `install_cleanup.sh`.
2. Make the script executable:
   ```bash
   chmod +x install_cleanup.sh
   ```
3. Run the script:
   ```bash
   ./install_cleanup.sh
   ```

## Uninstallation

Use the provided `uninstall_cleanup.sh` script to remove `cleanup.sh` from `/usr/local/bin` and delete the associated cron job.

### Uninstallation Script

```bash
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
```

### Running the Uninstallation Script

1. Save the uninstallation script to a file, for example, `uninstall_cleanup.sh`.
2. Make the script executable:
   ```bash
   chmod +x uninstall_cleanup.sh
   ```
3. Run the script:
   ```bash
   ./uninstall_cleanup.sh
   ```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

This project was assisted by ChatGPT, a language model developed by OpenAI.

