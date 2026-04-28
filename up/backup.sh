#!/bin/bash

# Configuration
BACKUP_DIR="/var/backups/mongodb"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
DB_NAME="livechat"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Run mongodump
mongodump --db $DB_NAME --out $BACKUP_DIR/$DATE

# Optional: Compress the backup
tar -czvf $BACKUP_DIR/$DB_NAME-$DATE.tar.gz -C $BACKUP_DIR $DATE
rm -rf $BACKUP_DIR/$DATE

# Keep only last 7 days of backups
find $BACKUP_DIR -type f -name "*.tar.gz" -mtime +7 -exec rm {} \;

echo "Backup completed: $BACKUP_DIR/$DB_NAME-$DATE.tar.gz"
