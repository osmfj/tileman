How to configure custom style

# Original rendering configutaion
  
1. Get OpenStreetMap Japan mapnik style.

  ```
  git clone https://github.com/osmfj/mapnik-stylesheets.git
  ```
  
2. fork it for your own style.

  ```
  git checkout -b <new-cool-style-for-my-map> master
  ```

   please replace <new-cool-style-for-my-map> with your favorite branch name
   
3. get coast line

  ```
  cd 
  get_coastline.sh
  ```
  
4. Edit style in XML

   TBD
   
5. locate your custom osm template

  ```
  cp osm.xml /opt/tileserver/share/
  ```
  
6. add tirex configuration

  ```
  vi /etc/tirex/render/mapnik/custom.conf
  ##
  #  Configuration for Mapnik custom map.
  #  /etc/tirex/renderer/mapnik/custom.conf
  ##
  #  symbolic name of this map
  name=custom
  
  #  tile directory
  tiledir=/var/lib/tirex/tiles/example

  #  zoom level allowed
  minz=0
  maxz=19
  
  mapfile=/opt/tilesrever/share/osm.xml
  ```

