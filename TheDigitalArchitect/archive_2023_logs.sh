#!/bin/bash

# Script to archive 2023 log files into old_logs.tar.gz and remove them
# Requirements:
# - Archive named exactly old_logs.tar.gz
# - Located in ~/project/logs
# - Only include files with 2023 in their name
# - Exclude and preserve app_2024-05-01.log

# Set the working directory
LOGS_DIR="$HOME/project/logs"

# Check if the logs directory exists
if [ ! -d "$LOGS_DIR" ]; then
    echo "Error: Directory $LOGS_DIR does not exist."
    exit 1
fi

# Navigate to the logs directory
cd "$LOGS_DIR" || {
    echo "Error: Could not change to directory $LOGS_DIR."
    exit 1
}

# Check if there are any 2023 log files
if ! ls *2023*.log >/dev/null 2>&1; then
    echo "Error: No log files with '2023' in their name found in $LOGS_DIR."
    exit 1
fi

# Check if old_logs.tar.gz already exists
if [ -f "old_logs.tar.gz" ]; then
    echo "Warning: old_logs.tar.gz already exists. Overwriting it."
fi

# Create the tar.gz archive with only 2023 log files
tar -czf old_logs.tar.gz *2023*.log 2>/dev/null || {
    echo "Error: Failed to create old_logs.tar.gz."
    exit 1
}

# Verify the archive was created
if [ -f "old_logs.tar.gz" ]; then
    echo "Archive old_logs.tar.gz created successfully."
    echo "Contents of old_logs.tar.gz:"
    tar -tzf old_logs.tar.gz
else
    echo "Error: Archive old_logs.tar.gz was not created."
    exit 1
fi

# Remove the 2023 log files
rm -f *2023*.log || {
    echo "Error: Failed to remove 2023 log files."
    exit 1
}

# Verify that app_2024-05-01.log still exists (if it was present)
if [ -f "app_2024-05-01.log" ]; then
    echo "Confirmed: app_2024-05-01.log was not archived or deleted."
else
    echo "Note: app_2024-05-01.log not found in $LOGS_DIR (was it present?)."
fi

# List remaining files in the directory
echo "Remaining files in $LOGS_DIR:"
ls -l

exit 0
