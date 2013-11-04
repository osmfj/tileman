#/usr/bin
#
# latest osmosis installer
#

# Download
cd /tmp
if [ -f osmosis-latest.tgz ]; then
  sudo rm -f osmosis-latest.tgz
fi
wget http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-latest.tgz

# Pre-Install
addgroup --system --quiet osmosis
adduser  --system --quiet osmosis

# Install
mkdir -p /usr/lib/osmosis
cd /usr/lib/osmosis;tar zxf /tmp/osmosis-latest.tgz
if [ -f /usr/bin/osmosis ]; then
  sudo mv /usr/bin/osmosis /usr/bin/osmosis.old
fi
ln -s /usr/lib/osmosis/bin/osmosis /usr/bin/osmosis
mkdir -p /var/lib/osmosis
chown osmosis /var/lib/osmosis

