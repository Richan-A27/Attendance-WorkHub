#!/bin/bash

# Database Restore Script for Isravel WorkHub
# Usage: ./restore-database.sh <backup_file>

# Configuration
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="isravel_workhub"
DB_USER="isravel"
DB_PASSWORD="isravel_password"

# Check if backup file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file>"
    echo "Example: $0 isravel_workhub_backup_20240115_020000.sql.gz"
    exit 1
fi

BACKUP_FILE=$1

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Starting database restore at $(date)"
echo "Backup file: $BACKUP_FILE"

# Decompress if needed
if [[ $BACKUP_FILE == *.gz ]]; then
    echo "Decompressing backup file..."
    TEMP_FILE=$(mktemp)
    gunzip -c "$BACKUP_FILE" > "$TEMP_FILE"
    RESTORE_FILE="$TEMP_FILE"
else
    RESTORE_FILE="$BACKUP_FILE"
fi

# Perform restore
PGPASSWORD=${DB_PASSWORD} psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} < ${RESTORE_FILE}

if [ $? -eq 0 ]; then
    echo "Restore completed successfully!"
    
    # Clean up temp file if it was created
    if [ -n "$TEMP_FILE" ]; then
        rm -f "$TEMP_FILE"
    fi
else
    echo "Restore failed!"
    
    # Clean up temp file if it was created
    if [ -n "$TEMP_FILE" ]; then
        rm -f "$TEMP_FILE"
    fi
    exit 1
fi

echo "Restore process completed at $(date)"
