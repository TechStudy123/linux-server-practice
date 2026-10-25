#!/bin/bash
# お知らせサイトのバックアップ（練習用）: 設定とデータを tar でまとめ、7日より古い写しを消す
set -eu
DEST=/data/backup
mkdir -p "$DEST"
tar czf "$DEST/notice-$(date +%Y%m%d).tar.gz" /etc/nginx /data/notice
find "$DEST" -name 'notice-*.tar.gz' -mtime +7 -print -delete
echo "backup done: $DEST/notice-$(date +%Y%m%d).tar.gz"
