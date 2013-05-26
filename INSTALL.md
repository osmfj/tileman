Setup instruction of tileman

Tested on Ubuntu 12.04 LTS 64bit

# Install TileMan for using a proxy/cache server of tile.openstreetmap.jp

If you only need tile proxy/cache server, just follow this instruction.
And you can serve original local tile images placed X/Y/Z folder.

The OpenStreetMap Japan team provide Ubuntu PPA for it.

## clone git repository.

We use submodule feature of git.
Please follows an instructon bellow.

```
git clone git://github.com/osmfj/tileman.git
git submodule init
git submodule update
```

## Install nginx

```
sudo apt-add-repository ppa:osmjapan/ppa
sudo apt-get update
sudo apt-get install nginx-extras
```

## Install TileMan

1. Install dependencies

  ```
  sudo apt-get install build-essential geoip-database dh-autoreconf lua5.1 libiniparser-dev lua-bitop
  ```

2. Install lua osm libraries

  ```
  sudo apt-get install lua-nginx-osm
  ```

3. Setup nginx configulation

  ```
  cd ../nginx
  sudo ./install.sh
  ```

4. Install render_expired

  ```
  sudo apt-get install render_expired
  ```

5. Setup nginx configuration

  ```
  sudo ln -s /etc/nginx/sites-available/tileproxy /etc/nginx/sites-enabled/tileproxy
  ```

  If you need SSL settings, enable ssl configuration

  ```
  sudo ln -s /etc/nginx/sites-available/tileproxy-ssl /etc/nginx/sites-enabled/tileproxy-ssl
  ```

  If you want to use special configuration in order to replace static tiles in specific region.
  A details are described in StaticTile.md.(TBD)
  
  ```
  sudo ln -s /etc/nginx/sites-available/statictile /etc/nginx/sites-enabled/statictile
  ```

7. Create cache folder

  ```
  sudo mkdir /home/tilecache
  sudo chmod 777 /home/tilecache
  ```

8. Restart nginx

  ```
  sudo service nginx restart
  ```

9. Test

  You can access to the nginx from your local machine. And VirtualHost name of the tile cache server is named 'tile' as default. So you have to add 'tile' entry on your local hosts file (not on the remote host).

  ```
  local% sudo vi /etc/hosts
  ##
  # Host Database
  #
  # localhost is used to configure the loopback interface
  # when the system is booting.  Do not change this entry.
  ##
  127.0.0.1  localhost tile
  255.255.255.255  broadcasthost
  ::1             localhost
  fe80::1%lo0  localhost
  ```

  You can see cached tiles like this, using url 'http://tile/0/0/0.png'

  ![tile image](https://dl.dropbox.com/u/442212/qiita/tilecache_image.png)

  If you are set for replacement of static tiles, hostname 'japan' is used for it.
  
  
# Install rendering system for generating original tiles.

You will need following softwares for serving original renderer.
First it shows a test case for mapnik example-map tirex rendering configuration.

## Install Dependencies

1. Mapnik rendering library

  ```
  sudo apt-add-repository ppa:osmjapan/ppa # if you did not add this yet
  sudo apt-get update
  sudo apt-get install python-software-properties
  sudo apt-get install libmapnik-dev
  ```

2. Tirex rendering engine

  ```
  sudo apt-get install tirex-core tirex-backend-mapnik \
       tirex-backend-wms tirex-example-map tirex-munin-plugin \
       tirex-nagios-plugin tirex-syncd
  ```

## example-map rendering server

1. Setup nginx configuration

  ```
  sudo ln -s /etc/nginx/sites-available/tileserver /etc/nginx/sites-enabled/tileserver
  ```

 If you need SSL settings, enable ssl configuration

  ```
  sudo ln -s /etc/nginx/sites-available/tileserver_ssl /etc/nginx/sites-enabled/tileserver_ssl
  ```

2. restert nginx

  ```
  sudo service nginx restart
  ```

3. Test

  You can access to the nginx from your local machine. And VirtualHost name of the tileserver is named 'tileserver' as default. So you have to add 'tileserver' entry on your local hosts file (not on the remote host).

  ```
  local% sudo vi /etc/hosts
  ##
  # Host Database
  #
  # localhost is used to configure the loopback interface
  # when the system is booting.  Do not change this entry.
  ##
  127.0.0.1  localhost tile tileserver
  255.255.255.255  broadcasthost
  ::1             localhost
  fe80::1%lo0  localhost
  ```

  You can see rendered tile, using url 'http://tileserver/0/0/0.png'
  It will be a world coast lines in zoom 0.
  

## OpenStreetMap planet data and rendering
  
  Now you can challenge your own rendering server.
  You need to prepare PostGIS and mapnik style for its work.
  
1. PostGIS 2.0 geo-spacial DBMS

  ```
  sudo apt-get install postgresql-9.1-postgis
  ```

2. Importing tools

  ```
  # osm2pgsql, osmoisis
  sudo apt-get install default-java # if not installed
  sudo apt-get install osm2pgsql osmosis
  ```

3. OpenStreetMap data setup

  ```
  sudo apt-get install openstreetmap-postgis-db-setup openstreetmap-mapnik-data
  ```

4. mapnik openstreetmap style and more

  Further instruction is in doc/custom_style.md
  It shows a practical environment with PostGIS/Mapnik/Tirex combination.

