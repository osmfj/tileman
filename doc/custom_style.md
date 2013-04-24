How to configure custom style

# Original rendering configutaion
  
1. Install Dependencies

  ```
  sudo apt-get install python-mapnik
  ```
  
2. Get OpenStreetMap Japan mapnik style.

  ```
  git clone https://github.com/osmfj/mapnik-stylesheets.git
  ```
  
3. fork it for your own style.

  ```
  git checkout -b <new-cool-style-for-my-map> master
  ```

   please replace <new-cool-style-for-my-map> with your favorite branch name
   
4. get coast line

  ```
  cd 
  get_coastline.sh
  ```
  
5. Edit style in XML

   TBD
   
6. locate your custom osm template

  ```
  cd ~/mapnik-stylesheets # or whatever directory you put the project in
  wget http://tile.openstreetmap.org/world_boundaries-spherical.tgz
  wget http://tile.openstreetmap.org/processed_p.tar.bz2
  wget http://tile.openstreetmap.org/shoreline_300.tar.bz2
  wget http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_populated_places.zip
  wget http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/110m/cultural/ne_110m_admin_0_boundary_lines_land.zip
  tar xzf world_boundaries-spherical.tgz
  tar xjf processed_p.tar.bz2 -C world_boundaries
  tar xjf shoreline_300.tar.bz2 -C world_boundaries
  unzip ne_110m_admin_0_boundary_lines_land.zip -d world_boundaries
  unzip ne_10m_populated_places.zip -d world_boundaries
  cd world_boundaries
  ln -s ne_110m_admin_0_boundary_lines_land.shp 110m_admin_0_boundary_lines_land.shp
  ln -s ne_110m_admin_0_boundary_lines_land.dbf 110m_admin_0_boundary_lines_land.dbf
  cd ..
  ./generate_xml.py --host localhost --port 5432 --user osm --password '' --dbname gis --symbols ./symbols/ --world_boundaries ./world_boundaries/ osm.xml > myosm.xml
  ```
  
7. add tirex configuration

  ```
  vi /etc/tirex/render/mapnik/custom.conf
  ##
  #  Configuration for Mapnik custom map.
  #  /etc/tirex/renderer/mapnik/custom.conf
  ##
  #  symbolic name of this map
  name=custom
  
  #  tile directory
  tiledir=/var/lib/tirex/tiles/custom

  #  zoom level allowed
  minz=0
  maxz=19
  
  mapfile=/opt/tilesrever/share/myosm.xml
  ```

