#!/bin/sh

# Uubntu/debian or not?
echo "Do you use Ubuntu/Debian?[N/y]"
read ans
if [ "$ans" = "y" -o "$ans" = "Y" ]; then
  echo "You can install libraries from PPA"
  echo "Please follow an instraction on root privilege."
  echo " # apt-add-repository ppa:miurahr/openstreetmap"
  echo " # apt-get install lua-bitop libiniparser-dev"
  exit 0
fi
echo "build and install libraries"
echo "continue?[N/y]"
read ans
if [ "$ans" = "y" -o "$ans" = "Y" ]; then
echo "You should install lua5.1 development files."
echo "Need sudo for installation"

  sudo mkdir -p /usr/local/lib/lua/5.1
  sudo mkdir -p /usr/local/lib/iniparser
  tar xf LuaBitOp-1.0.2.tar.gz
  (cd LuaBitOp-1.0.2 ; \
     patch -p1 -i ../LuaBitOp_ubuntu.patch && \
     make LUA=lua5.1&& \
     sudo make LUA=lua5.1 install)

  (cd iniparser3.0b; make && make install )
fi
