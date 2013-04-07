#!/bin/sh
sudo apt-get install liblua5.1-0-dev
sudo mkdir -p /usr/local/lib/lua/5.1/lib
tar xf LuaBitOp-1.0.2.tar.gz
(cd LuaBitOp-1.0.2 ; \
patch -p1 -i ../LuaBitOp_ubuntu.patch && \
make&& \
sudo make install)
