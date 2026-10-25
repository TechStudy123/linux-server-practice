# linux-server-practice

「Linux サーバー構築・運用 〜サービス・ネットワーク・Web サーバー・ログで障害を切り分ける〜」のハンズオンで使う教材ファイルです。

## 取り出し方

サーバー（AlmaLinux 10）のターミナルで、次のとおりに取り出します。手順は各回の説明資料のとおりです。

```bash
cd ~
curl -fsSLO https://raw.githubusercontent.com/TechStudy123/linux-server-practice/main/practice.tar.gz
tar -tzf practice.tar.gz | head
tar -xzf practice.tar.gz
```

| ファイル | 使う回 | 中身 |
|---|---|---|
| `practice/app/app.py`・`notices.json`・`notice.service` | ハンズオン2 | お知らせのアプリ（Python の標準ライブラリだけ）・データ・ユニットファイル |
| `practice/www/index.html` | ハンズオン4 | 試しの Web サーバーで返すページ |
| `practice/site/index.html` | ハンズオン5 | お知らせサイトのトップページ |
| `practice/nginx/notice.conf`・`notice_api.conf`・`notice_https.conf` | ハンズオン5〜7 | Nginx の設定の見本（各回の終わりの形） |
| `practice/logs/access.log`・`error.log` | ハンズオン8 | 集計の練習用のログ（架空のデータ。IP は説明用に予約されたアドレス） |
| `practice/backup/` | ハンズオン10 | バックアップのスクリプトと、systemd のサービス・タイマー |
| `practice/start.sh` | 各回 | 途中の回から始めるときに、その回を始める時点の状態を作る（`sudo bash ~/practice/start.sh H5`） |
| `practice/break.sh` | ハンズオン12・13 | わざと1か所だけ不具合を仕込む（`sudo bash ~/practice/break.sh net1` など） |

スクリプトは、実行する前に `less` で中身を読んでください。
