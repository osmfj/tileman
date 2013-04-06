タイルキャッシュサーバの実現方法
==================================


前提は、Ubuntu 11.10(amd64)サーバです。

1. aptでnginx-extra入れてください。

    $ sudo apt-get install nginx-extra

2. 本リポジトリを取得します。

    $ git clone git://github.com/osmfj/tilecache.git

tilecache ディレクトリが作成され、その配下にプロジェクトのファイルが配置されます。

3. nginxの追加設定が nginxディレクトリに格納されています。
それらを/etc/nginx/配下にディレクトリ構成をそのままに配置してください。
nginxディレクトリにあるinstall.shは、上記を自動的に行うためにあります。
これを実行すると、適切に/etc/nginxに配置するようにしています。

何をしているかは、スクリプトのなかを確認してください。コマンドの羅列になっています。

4. キャッシュ用のディレクトリ作成

/home/tilecache ディレクトリを作ってください。
ここには、upstream(tile.openstreetmap.org)から取得したタイル画像のキャッシュが格納されます。
nginxの実行ユーザから書き込まれる必要があるので、chmod 777 /home/tilecacheするといいでしょう。

これ以外のディレクトリにしたい場合は、

nginx/conf.d/tilecache.conf をあわせて書き換えます。

    $ git checkout -b mysite master
    $ vi nginx/conf.d/tilecache.conf 

ブランチを分けて修正することで、開発リポジトリの変更の影響を受けにくいでしょう。

    proxy_cache_path /home/tilecache levels=1:2:2 keys_zone=tilecache:100m max_size=36G inactive=30d;

という行の２つ目のパラメータが対応します。例えば、 /var/cache/tilecache など。
ディスクサイズにあわせて、max_sizeも調整してください。

最大でどこまでキャッシュ用にディスクを使っていいかの設定です。


