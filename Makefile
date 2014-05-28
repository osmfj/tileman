#
# makefile
#
# Distro detection
DISTRO_ID=`lsb_release -i|cut -f 2`
ifeq ($(strip $(DISTRO_ID)),'Ubuntu')
DISTRO=debian
else ifeq ($(strip $(DISTRO_ID)),'Debian')
DISTRO=debian
else ifeq ($(strip $(DISTRO_ID)),'LinuxMint')
DISTRO=debian
else
DISTRO=redhat
endif

PREFIX   ?=	/opt/tileman
DESTDIR  ?=	${PREFIX}/bin/
HTMLDIR  ?=	${PREFIX}/html/
CACHEDIR ?=	${PREFIX}/cache/
STATICDIR?=	${PREFIX}/tiles/
CONFDIR  ?=	${PREFIX}/etc/
NGINX    ?=	${CONFDIR}/nginx
WORKDIR  ?=	${PREFIX}/osmosis

.PHONY: install test test_install test_service_start test_db_load

all:

install: directories nginx_$(DISTRO) utils osmosis statictiles

directories:
	mkdir -p $(DESTDIR)
	mkdir -p $(WORKDIR)
	mkdir -p $(HTMLDIR)
	mkdir -p $(CACHEDIR)
	chmod 777 $(CACHEDIR)
	mkdir -p $(STATICDIR)

statictiles: directories
	bzcat data/Liancourt_Rocks_lang_ja_tiles.tar.bz2 |(cd $(STATICDIR);tar xf -)

nginx_debian:
	install nginx/tileman_proxy_params $(NGINX)/
	install nginx/tileman_ssl_params $(NGINX)/
	install nginx/conf.d/* $(NGINX)/conf.d/
	install nginx/sites/* $(NGINX)/sites-available/

nginx_redhat:
	install nginx/tileman_proxy_params $(NGINX)/
	install nginx/tileman_ssl_params $(NGINX)/
	install nginx/conf.d/tileman.conf $(NGINX)/conf.d/_tileman.conf
	install nginx/sites/tileman-proxy $(NGINX)/conf.d/tileman-proxy.conf.ex
	install nginx/sites/tileman-proxy-ssl $(NGINX)/conf.d/tileman-proxy-ssl.conf.ex
	install nginx/sites/tileman-server $(NGINX)/conf.d/tileman-server.conf.ex
	install nginx/sites/tileman-server-ssl $(NGINX)/conf.d/tileman-server-ssl.conf.ex

utils:
	install -c bin/* $(DESTDIR)
	install -c etc/*.conf $(CONFDIR)

osmosis:
	cp osmosis/fabrik.txt $(WORKDIR)/configuration.txt

test: test_$(DISTRO)

test_debian:

test_redhat:

travis_test_install:
	sudo test/travis_test_install.sh

test_install: test_install_$(DISTRO)

test_install_debian:
	sudo test/test_install.sh

test_install_redhat:

test_service_start:
	sudo service tirex-backend-manager start
	sudo service tirex-master start
	sudo service nginx start

test_dbload:
	sudo test/load.sh
