Setup instruction of tilecache

Tested on Ubuntu 12.04 LTS

# Install Tilecache for using a proxy/cache server of tile.openstreetmap.org

If you only need tile proxy/cache server, just follow this instruction.
And you can serve original local tile images placed X/Y/Z folder.

## Install nginx

```
sudo apt-add-repository ppa:miurahr/openstreetmap
sudo apt-get update
sudo apt-get install nginx-extras
```

## Install tilecache

1. Install dependencies

  ```
  sudo apt-get install build-essential geoip-database dh-autoreconf liblua5.1-bitop0 lua5.1
  ```

2. Install libraries

  ```
  cd lib
  sudo ./install.sh
  ```

3. Setup nginx configulation

  ```
  cd ../nginx
  sudo ./install.sh
  ```

4. Install render_expire

  ```
  cd ../render_expire
  ./autogen.sh
  ./configure --prefix=/opt/tileserver
  make
  sudo make
  ```

5. Setup nginx configuration

  ```
  sudo ln -s /etc/nginx/sites-available/tileproxy /etc/nginx/sites-enabled/tileproxy
  ```

  If you need SSL settings, enable ssl configuration

  ```
  sudo ln -s /etc/nginx/sites-available/tileproxy-ssl /etc/nginx/sites-enabled/tileproxy-ssl
  ```

6. Create cache folder

  ```
  sudo mkdir /home/tilecache
  sudo chmod 777 /home/tilecache
  ```

7. Restart nginx

  ```
  sudo service nginx restart
  ```

8. Test

  You can access to the nginx from your local machine. And the tilecache server's VirtualHost is named 'tile' as default. So you have to add 'tile' entry on your local hosts file (not on the remote host).

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

  You can see cached tiles like this.

  ![tile image](https://dl.dropbox.com/u/442212/qiita/tilecache_image.png)

# Install rendering system for generating original tiles.

You will need following softwares for serving original renderer.

## Install Dependencies

1. PostGIS 2.0

  ```
  sudo apt-get install python-software-properties
  sudo apt-add-repository ppa:sharpie/for-science
  sudo apt-add-repository ppa:sharpie/postgis-stable
  sudo apt-add-repository ppa:ubuntugis/ubuntugis-unstable
  sudo apt-get update
  sudo apt-get install postgresql-9.1-postgis2
  ```

2. Mapnik

  ```
  sudo apt-add-repository ppa:miurahr/openstreetmap # if you did not add this yet
  sudo apt-get update
  sudo apt-get install libmapnik-dev
  ```

3. Tirex

  ```
  sudo apt-get install tirex-core tirex-backend-mapnik \
       tirex-backend-wms tirex-example-map tirex-munin-plugin \
       tirex-nagios-plugin tirex-syncd
  ```

4. Importing tools

  ```
  # osm2pgsql, osmoisis
  sudo apt-get install default-java # if not installed
  sudo apt-get install osm2pgsql osmosis
  ```

