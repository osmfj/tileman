Setup instruction of tilecache

Tested on Ubuntu 12.04 LTS

# Install Tilecache for using a proxy/cache server of tile.openstreetmap.org

If you only need tile proxy/cache server, just follow this instruction.
And you can serve original local tile images placed X/Y/Z folder.

## Install nginx

```
sudo apt-add-repository ppa:miurahr/openstreetmap
sudo apt-get update
sudo apt-get install nginx nginx-extras
```

## Install tilecache

1. Install dependencies

  ```
  sudo apt-get install build-essential geoip-database dh-autoreconf lua5.1
  ```

2. Install lua-nginx-redis

  ```
  git clone git://github.com/osmfj/tilecache.git
  cd pkgs
  sudo dpkg -i /vagrant/tilecache/pkgs/lua-nginx-redis_0.15-1_all.deb
  ```

3. Install libraries

  ```
  cd ../lib
  sudo /install.sh
  ```

4. Setup nginx configulation

  ```
  cd ../nginx
  sudo ./install.sh
  ```

5. Install render_expire

  ```
  cd ../render_expire
  ./autogen.sh
  ./configure
  make
  sudo make
  ```

6. Setup nginx configuration

  ```
  sudo ln -s /etc/nginx/sites-available/tileproxy /etc/nginx/sites-enabled/tileproxy
  ```

  If you need SSL settings, enable ssl configuration

  ```
  sudo ln -s /etc/nginx/sites-available/tileproxy-ssl /etc/nginx/sites-enabled/tileproxy-ssl
  ```

8. Restart nginx

  ```
  sudo service nginx restart
  ```

9. Test

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
  sudo apt-get install postgis2
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


