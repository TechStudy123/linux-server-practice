#!/bin/bash
# 練習用: 「ハンズオンN を始める時点」の状態を作ります（途中の回から始める・作り直すとき）。
# 使い方: sudo bash ~/practice/start.sh H5
#   ハンズオン1 が終わったサーバー（ホスト名 web01・タイムゾーン Asia/Tokyo）で、~/practice に教材を展開してから実行します。
#   AWS の画面での操作（セキュリティグループの許可・ディスクの追加）は、このスクリプトではできません。説明資料のとおりに行ってください。
set -eu
N="${1:-}"; N="${N#H}"; N="${N#h}"
[[ "$N" =~ ^[0-9]+$ ]] && [ "$N" -ge 2 ] && [ "$N" -le 13 ] || { echo "使い方: sudo bash ~/practice/start.sh H2〜H13"; exit 1; }
[ "$(id -u)" -eq 0 ] || { echo "sudo を付けて実行してください"; exit 1; }
P="$(cd "$(dirname "$0")" && pwd)"
WSL=0; grep -qi microsoft /proc/version && WSL=1
SEL=0; command -v getenforce >/dev/null && [ "$(getenforce)" != "Disabled" ] && SEL=1
say() { echo "== $*"; }

app() {   # ハンズオン2 の終わり
  say "アプリを動かす（notice.service）"
  id notice >/dev/null 2>&1 || useradd -r -s /sbin/nologin notice
  install -d /opt/notice /srv/notice/data
  install -m 644 "$P/app/app.py" /opt/notice/app.py
  [ -f /srv/notice/data/notices.json ] || install -m 644 "$P/app/notices.json" /srv/notice/data/notices.json
  install -m 644 "$P/app/notice.service" /etc/systemd/system/notice.service
  systemctl daemon-reload; systemctl enable --now notice
}
fw() {    # ハンズオン4 の終わり
  say "firewalld を入れて、http を許可する"
  rpm -q firewalld >/dev/null || dnf -y -q install firewalld
  firewall-offline-cmd --list-services | grep -qw ssh || firewall-offline-cmd --add-service=ssh
  systemctl enable --now firewalld
  firewall-cmd -q --permanent --add-service=http; firewall-cmd -q --reload
}
web() {   # ハンズオン5 の終わり
  say "Nginx でトップページを返す"
  rpm -q nginx policycoreutils-python-utils >/dev/null || dnf -y -q install nginx policycoreutils-python-utils
  install -d /srv/notice/html
  install -m 644 "$P/site/index.html" /srv/notice/html/index.html
  if [ $SEL = 1 ]; then
    semanage fcontext -a -t httpd_sys_content_t '/srv/notice(/.*)?' 2>/dev/null || semanage fcontext -m -t httpd_sys_content_t '/srv/notice(/.*)?'
    restorecon -R /srv/notice
  fi
  install -m 644 "$P/nginx/notice.conf" /etc/nginx/conf.d/notice.conf
  nginx -t; systemctl enable --now nginx; systemctl reload nginx
}
api() {   # ハンズオン6 の終わり
  say "/api/ をアプリに取り次ぐ"
  install -m 644 "$P/nginx/notice_api.conf" /etc/nginx/conf.d/notice.conf
  [ $SEL = 1 ] && setsebool -P httpd_can_network_connect on
  nginx -t; systemctl reload nginx
}
tls() {   # ハンズオン7 の終わり
  say "HTTPS にする（自己署名の証明書）"
  if [ ! -f /etc/pki/tls/certs/notice.crt ]; then
    openssl req -x509 -nodes -newkey rsa:2048 -days 365 -subj "/CN=notice.example.test" \
      -keyout /etc/pki/tls/private/notice.key -out /etc/pki/tls/certs/notice.crt 2>/dev/null
    chmod 600 /etc/pki/tls/private/notice.key
  fi
  install -m 644 "$P/nginx/notice_https.conf" /etc/nginx/conf.d/notice.conf
  firewall-cmd -q --permanent --add-service=https; firewall-cmd -q --reload
  nginx -t; systemctl reload nginx
}
data() {  # ハンズオン9 の終わり（/data は説明資料の手順で用意する）
  say "/data を確かめる"
  if [ $WSL = 1 ]; then install -d /data
  elif ! mountpoint -q /data; then
    echo "/data がマウントされていません。ハンズオン9 の手順でディスクを足して /data を用意してから、もう一度実行してください。"; exit 1
  fi
}
backup() { # ハンズオン10 の終わり
  say "データを /data に移し、毎日のバックアップを設定する"
  install -d /data/notice /data/backup
  if [ -f /srv/notice/data/notices.json ]; then mv /srv/notice/data/notices.json /data/notice/notices.json; fi
  [ -f /data/notice/notices.json ] || install -m 644 "$P/app/notices.json" /data/notice/notices.json
  sed -i 's#^Environment=NOTICE_DATA=.*#Environment=NOTICE_DATA=/data/notice/notices.json#' /etc/systemd/system/notice.service
  systemctl daemon-reload; systemctl restart notice
  install -m 755 "$P/backup/notice-backup.sh" /usr/local/bin/notice-backup.sh
  install -m 644 "$P/backup/notice-backup.service" "$P/backup/notice-backup.timer" /etc/systemd/system/
  systemctl daemon-reload; systemctl enable --now notice-backup.timer
}
ops() {   # ハンズオン11 の終わり
  say "作業用ユーザー opsuser と SSH の設定"
  id opsuser >/dev/null 2>&1 || useradd -m opsuser
  install -d -m 700 -o opsuser -g opsuser /home/opsuser/.ssh
  if [ -f /home/ec2-user/.ssh/authorized_keys ]; then
    install -m 600 -o opsuser -g opsuser /home/ec2-user/.ssh/authorized_keys /home/opsuser/.ssh/authorized_keys
  fi
  echo 'opsuser ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/opsuser; chmod 440 /etc/sudoers.d/opsuser; visudo -cf /etc/sudoers.d/opsuser
  printf 'PermitRootLogin no\n' > /etc/ssh/sshd_config.d/10-hardening.conf
  sshd -t; systemctl reload sshd
}

[ "$N" -ge 3 ] && app
[ "$N" -ge 4 ] && { rpm -q bind-utils >/dev/null || dnf -y -q install bind-utils; }   # ハンズオン3 で入れた dig
[ "$N" -ge 5 ] && fw
[ "$N" -ge 6 ] && web
[ "$N" -ge 7 ] && api
[ "$N" -ge 8 ] && tls
[ "$N" -ge 10 ] && data
[ "$N" -ge 11 ] && backup
[ "$N" -ge 12 ] && ops
echo "ハンズオン$N を始める状態になりました。"
