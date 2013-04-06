タイルキャッシュサーバの実現方法
==================================


前提は、Ubuntu 11.10(amd64)サーバです。

ソフトウエアインストール
------------------------

aptでgit, nginxを入れてください。nginxは最新版が必要です。

    $ sudo apt-add-repositry ppa:nginx/development 
    $ sudo apt-get update
    $ sudo apt-get install git nginx-extras

本リポジトリを取得します。
---------------------------

    $ git clone git://github.com/osmfj/tilecache.git

tilecache ディレクトリが作成され、その配下にプロジェクトのファイルが配置されます。

nginxの追加設定
---------------

nginxにいれる追加の設定がnginxディレクトリに格納されています。
それらを/etc/nginx/配下にディレクトリ構成をそのままに配置してください。
nginxディレクトリにあるinstall.shは、上記を自動的に行うためにあります。
これを実行すると、適切に/etc/nginxに配置するようにしています。

何をしているかは、スクリプトのなかを確認してください。コマンドの羅列になっています。

キャッシュ用のディレクトリ作成
-------------------------------

/home/tilecache ディレクトリを作ってください。
ここには、upstream(tile.openstreetmap.org)から取得したタイル画像のキャッシュが格納されます。
nginxの実行ユーザから書き込まれる必要があるので、chmod 777 /home/tilecacheするといいでしょう。

これ以外のディレクトリにしたい場合は、

nginx/conf.d/tilecache.conf をあわせて書き換えます。

    $ git checkout -b mysite master
    $ vi nginx/conf.d/tilecache.conf 
    $ cd nginx
    $ ./install.sh

ブランチを分けて修正することで、開発リポジトリの変更の影響を受けにくいでしょう。

    proxy_cache_path /home/tilecache levels=1:2:2 keys_zone=tilecache:100m max_size=36G inactive=30d;

という行の２つ目のパラメータが対応します。例えば、 /var/cache/tilecache など。
ディスクサイズにあわせて、max_sizeも調整してください。

最大でどこまでキャッシュ用にディスクを使っていいかの設定です。

ホスト名部分の設定
------------------

ホスト名は、それぞれの環境で合わせる必要があります。

    $ vi nginx/sites/tileproxy
    $ vi nginx/sites/tileproxy_ssl
    $ vi nginx/sites/statictile
    $ cd nginx
    $ ./install.sh

一つ目は、キャッシュだけのサーバの設定です。
２つ目は、キャッシュする他、httpsでタイル配信します。
　これは、たとえばhttpsでサービスを提供しているWebサイトにおいて
　httpの地図を張り付けると、Internet Explorerで警告をうけることを
　回避するために利用可能です。
３つめは、部分的に自前で作成したタイルを配信するための設定例です。
例えば、愛知県は自分でレンダリングしたタイル画像を配信したいが、
　ソレ以外については、osm.orgの既定で構わない場合などに便利です。

設定の有効化
----------------

    $ sudo ln -s /etc/nginx/sites-avaliable/tileproxy /etc/nginx/sites-enabled/tileproxy

上記のように、ubuntu/debianの場合は設定を有効になるようにします。

Nginx再起動
---------------

    $ sudo service nginx testconfig
    $ sudo service nginx restart

１行目は設定に不具合がないかのチェックです。
