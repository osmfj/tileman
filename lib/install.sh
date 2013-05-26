#!/bin/sh

# Uubntu/debian or not?
echo "Do you use Ubuntu/Debian?[N/y]"
read ans
if [ "$ans" = "y" -o "$ans" = "Y" ]; then
  echo "You can install libraries from PPA"
  echo "Please follow an instruction on root privilege."
  echo " # apt-add-repository ppa:osmjapan/ppa"
  echo " # apt-get install lua-bitop libiniparser-dev"
  exit 0
fi
echo "Build and install libraries now..."
echo "You should install lua5.1 development files in advance."
echo "Need sudo and your password..."
echo "continue?[N/y]"
read ans
if [ "$ans" = "y" -o "$ans" = "Y" ]; then
  echo "Build Lua BitOp lib..."
  sudo mkdir -p /usr/local/lib/lua/5.1
  tar xf LuaBitOp-1.0.2.tar.gz
  (cd LuaBitOp-1.0.2 ; \
     patch -p1 -i ../LuaBitOp_ubuntu.patch && \
     make LUA=lua5.1&& \
     sudo make LUA=lua5.1 install)
  echo "Build iniparser lib..."
  (cd iniparser; make && make install )
fi
