#!/bin/bash
# 練習用: お知らせサイトに、わざと1か所だけ不具合を仕込みます（ハンズオン12・13）。
# 使い方: sudo bash ~/practice/break.sh net1   （net1・net2・web1・web2 のどれか1つ）
# 何を変えたかは、このファイルには書いてありますが、先に読まずに、切り分けの地図で探してください。
set -eu
[ "$(id -u)" -eq 0 ] || { echo "sudo を付けて実行してください"; exit 1; }
case "${1:-}" in
  net1) firewall-cmd -q --permanent --remove-service=http --remove-service=https; firewall-cmd -q --reload ;;
  net2) grep -q 'notice.example.test' /etc/hosts && sed -i '/notice.example.test/d' /etc/hosts
        echo '192.0.2.200  notice.example.test' >> /etc/hosts ;;
  web1) U=$(logname 2>/dev/null || echo ec2-user); H=$(getent passwd "$U" | cut -d: -f6)
        sed 's#<h1>社内のお知らせ</h1>#<h1>社内のお知らせ（新しいページ）</h1>#' /srv/notice/html/index.html > "$H/new.html"
        chown "$U:" "$H/new.html"; mv "$H/new.html" /srv/notice/html/new.html ;;
  web2) systemctl stop notice ;;
  *) echo "使い方: sudo bash ~/practice/break.sh net1|net2|web1|web2"; exit 1 ;;
esac
echo "不具合を1つ仕込みました（${1}）。切り分けの地図で、外側から順に確かめてください。"
