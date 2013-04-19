#
# iniparser Makefile
#

# Compiler settings
CC      = gcc
CFLAGS  = -O2 -fPIC -Wall -ansi -pedantic

# Ar settings to build the library
AR	    = ar
ARFLAGS = rcv

SHLD = ${CC} ${CFLAGS}
LDSHFLAGS = -shared -Wl,-Bsymbolic  -Wl,-rpath -Wl,/usr/lib -Wl,-rpath,/usr/lib
LDFLAGS = -Wl,-rpath -Wl,/usr/lib -Wl,-rpath,/usr/lib

# Set RANLIB to ranlib on systems that require it (Sun OS < 4, Mac OSX)
# RANLIB  = ranlib
RANLIB = true
RM      = rm -f

LIBTOOL=/usr/bin/libtool
INSTALL=/usr/bin/install -c
DESTDIR=/usr/local/lib

# Implicit rules

SUFFIXES = .o .c .h .a .so .sl

COMPILE.c=$(LIBTOOL) --mode=compile $(CC) $(CFLAGS) -c
.c.o:
	@(echo "compiling $< ...")
	@($(COMPILE.c) -o $@ $<)


SRCS = src/iniparser.c \
	   src/dictionary.c

OBJS = $(SRCS:.c=.o)

default:	libiniparser.a libiniparser.so libiniparser.la

libiniparser.a:	$(OBJS)
	@$(LIBTOOL) --mode=link $(CC) $(CFLAGS) --static -o libiniparser.a $(OBJS)

libiniparser.la:	$(OBJS)
	@$(LIBTOOL) --mode=link $(CC) $(CFLAGS) --static -o libiniparser.la $(OBJS)

libiniparser.so:	$(OBJS)
	@$(LIBOOL) --mode=link $(SHLD) $(LDSHFLAGS) -o $@.3 $(OBJS) $(LDFLAGS) \
		-Wl,-soname=`basename $@`.3

install:	libiniparser.la libiniparser.a libiniparser.so
	@$(LIBOOL) --mode=install $(INSTALL) libiniparser.a $(DESTDIR)
	@$(LIBOOL) --mode=install $(INSTALL) libiniparser.la $(DESTDIR)
	@$(LIBOOL) --mode=install $(INSTALL) libiniparser.so.3 $(DESTDIR)

clean:
	$(RM) $(OBJS)

veryclean:
	$(RM) $(OBJS) libiniparser.a libiniparser.so*
	rm -rf ./html ; mkdir html
	cd test ; $(MAKE) veryclean

docs:
	@(cd doc ; $(MAKE))
	
check:
	@(cd test ; $(MAKE))
