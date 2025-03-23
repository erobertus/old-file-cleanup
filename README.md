# Cleanup Script

## Purpose

The `cleanup.sh` script is designed to clean up files and directories within a specified directory. It recursively deletes files older than a specified number of days and removes any empty directories. This script can be scheduled to run automatically using cron jobs.

## Features

- Deletes files older than a specified number of days.
- Removes empty directories.
- Supports configurable log output: syslog or terminal.
- Retention period is configurable via `-n` option (default: 180 days).
- Install and uninstall scripts for easy setup and removal.
- Automatically configures log rotation if terminal logging is selected.

## Usage

### Script Usage

```bash
cleanup.sh [-p directory] [-n days] [-l]
```

- `-p directory`: The directory to clean (default: `/var/spool/asterisk/monitor`).
- `-n days`: Number of days to keep files (default: `180`).
- `-l`: Log actions to syslog. If not specified, output is printed to terminal.

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

Use the provided `install_cleanup.sh` script to install `cleanup.sh`, choose logging method, set retention period, and configure a cron job.

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

### What the installer does:
- Installs `cleanup.sh` to `/usr/local/bin`.
- Prompts for time of day to run.
- Asks how many days of files to retain (default: 180).
- Prompts for logging method:
   - **Syslog**: Passes `-l` to script; cron output is discarded.
   - **Terminal**: Redirects output to `/var/log/cleanup.log` and creates a logrotate config at `/etc/logrotate.d/cleanup_log`.
- Adds or replaces the cron job.

## Uninstallation

Use the provided `uninstall_cleanup.sh` script to remove `cleanup.sh`, its cron job, and the logrotate configuration (if created).

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

### What the uninstaller does:
- Removes `/usr/local/bin/cleanup.sh`.
- Removes any related cron job.
- Deletes `/etc/logrotate.d/cleanup_log` if it exists.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

This project was assisted by ChatGPT, a language model developed by OpenAI.

