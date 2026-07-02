#!/bin/bash

# Database Backup Script for Isravel WorkHub
# Usage: ./backup-database.sh

# Configuration
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="isravel_workhub"
DB_USER="isravel"
DB_PASSWORD="isravel_password"
BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/isravel_workhub_backup_${TIMESTAMP}.sql"

# Create backup directory if it doesn't exist
mkdir -p ${BACKUP_DIR}

echo "Starting database backup at $(date)"

# Perform backup
PGPASSWORD=${DB_PASSWORD} pg_dump -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} > ${BACKUP_FILE}

if [ $? -eq 0 ]; then
    echo "Backup completed successfully: ${BACKUP_FILE}"
    
    # Compress the backup
    gzip ${BACKUP_FILE}
    echo "Backup compressed: ${BACKUP_FILE}.gz"
    
    # Keep only last 7 days of backups
    find ${BACKUP_DIR} -name "isravel_workhub_backup_*.sql.gz" -type f -mtime +7 -delete
    echo "Old backups removed (older than 7 days)"
else
    echo "Backup failed!"
    exit 1
fi

echo "Backup process completed at $(date)"
