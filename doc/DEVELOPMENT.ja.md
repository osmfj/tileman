Developmenter note
=====================

開発は、github.com[*0]で行なっています。

名前は、キャッシュになっていますが、（最初はキャッシュの構築から開始したため）
OSMの独自タイル配信サーバの機能をもたせる計画です。

開発に興味のある方、一緒に研究しませんか。

Architecture
------------------

OSMのwikiでは、apacheにmod_tile[*1]を導入し、mapnik[*3]ライブラリを使った
Tirex[*2]がタイル画像を生成する方法が説明されています。
また、DBMSには、PostGISを用いて、 osm2pgsqlツールによって最新データを
取り込むようです。osmosisツールを使うことで、自動更新ができます。

独自タイル配信サーバの開発では、次のアーキテクチャを考えています。


Roadmap
============

Ver 0.8
----
* nginxサーバで、タイルキャッシュ機能を提供します。(DONE)
* リクエストのx/y/z値のチェックをおこなって不正なアクセスを
  抑止します。(in progress)
* tile.openstreetmap.orgの地域分散プログラム(CDN)へ参加可能な
　機能を備えます。(DONE)

Ver 0.9
----
* PostGISデータベースに日本地域のOSMデータを日次で
  自動更新できるようにします。(ほぼ完了) [*9]
* アクセス元が日本国内かどうかを判定して、独自タイルの配信を
   切り替えます。(完了)
* リクエストのx/y/z値をチェックして、レンダリング対象かどうかを
　判定できます。(未実装）

Ver 1.0
----
* nginxサーバのLUA拡張を利用して、mod_tile相当を実装します。
* タイル生成は、Tirex[*2]で行います。
* 生成されたタイル画像ファイルは、ファイルシステムに格納されます。
* nginxサーバとTirexは、UDPソケット通信でコマンドをやり取りします。

Ver 2.0
----

* Redis Key-Value-Storeを活用して、expire 情報を管理します。
* Redis Pub/Subを利用して、コマンドをやり取りします。
* Tirexを拡張して、redis pub/subに対応させます。
* renderd_expireを拡張して、redis pub/subに対応させます。
* nginx-luaから、redis pub/subを利用したコマンド利用させます。

Ver 3.0
----

* Redis KVSへタイル格納します。

mod_tile相当とは
----
* 独自タイル生成を、リクエストに応じて、on the flyで実施します。
* データベースの更新にあわせて、古くなったタイル画像を削除し、
　再度生成されるようにします。
* タイル画像が古い（expire)の場合でも、レスポンスを確保するため
　古いタイルを返送するが、httpでの画像の有効期間を再生成に
　必要な時間を動的に計算して、設定します。
　ユーザが再度表示しようとすると、新しいタイルになります。　


Running environment
=============

* 環境は、Ubuntu 11.10(64bit)です。
* Nightly buildのmapnikを使っています。[*5]
* nginxは、nginx-extra packageを使います。
* Osmosis は、Wiki[*8]からLatest Stable Versionをダウンロードし、/opt/osmosisに展開します。
* luaからredisデータベースへのアクセスは、OpenRestyのLua-redis[*6]モジュールを使います。
* Tirexは、ドキュメントに従ってmake debして、パッケージを導入します。[*7]
* redis-server パッケージを導入します。(apt-get install redis-server)
* 必要なdirectoryを掘ります。

参考 Mapnik2.2ビルド
---

最新版のmapnikをgit等で取り寄せて、パッケージをつくるときは、
パッケージ生成用のツールがあるので、参考にすると良い。

- https://github.com/mapnik/mapnik-packaging/tree/master/debian-nightlies


Install
==========

上記実行環境を整えたあと、

    $ git clone git://github.com/osmfj/tilecache.git
    $ cd tilecache
    $ (cd pkgs; sudo dpkg -i lua-nginx-redis_0.15-1_all.deb)

これで、redisにアクセスできる環境ができます。このパッケージはUbuntu raringからしか提供されていないので、同梱されています。

    $ (cd nginx; sudo ./install.sh)
    
これで、nginxの設定が導入されます。サーバ名はtileになっている想定です。

    $ cd render_expire
    $ make
    $ sudo make install
    $ cd ..

これで、render_expireが/opt/tileserver/bin に導入されます。



Directories
=============

    /home/tilecache ... tile cache directory for nginx, 要書き込み権限　
    /opt/tileserver ... application directory
    /opt/osmosis    ... osmosisのバイナリを展開する
    /opt/tileserver/bin/ lib/ share/  locate application bin/data
    /var/opt/tileserver ... locate application output, rendered tiles
    /var/opt/osmosis ... osmosisの設定や状態　要書き込み権限 osmosisで


External Links
===============

* [*0] https://github.com/osmfj/tilecache
* [*1] http://wiki.openstreetmap.org/wiki/Mod_tile
* [*2] http://wiki.openstreetmap.org/wiki/Tirex
* [*3] http://wiki.openstreetmap.org/wiki/Mapnik
* [*4] http://nginx.org/ja/
* [*5] https://launchpad.net/~mapnik/+archive/nightly-trunk
* [*6] https://github.com/agentzh/lua-resty-redis
* [*7] http://wiki.openstreetmap.org/wiki/Tirex/Building_and_Installing
* [*8] http://wiki.openstreetmap.org/wiki/Osmosis
* [*9] http://wiki.openstreetmap.org/wiki/Minutely_Mapnik
