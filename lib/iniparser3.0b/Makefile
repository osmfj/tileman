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

SRCDIR=./src/
OUTDIR=./build/

# Implicit rules

SUFFIXES = .o .c .h .a .so .sl .lo

COMPILE.c=$(CC) $(CFLAGS) -c
LTCOMPILE.c=$(LIBTOOL) --tag=CC --mode=compile $(CC) $(CFLAGS) -c

SRCS = $(SRCDIR)iniparser.c \
	   $(SRCDIR)dictionary.c

OBJS = $(OUTDIR)iniparser.o $(OUTDIR)dictionary.o
LTOBJS = $(OUTDIR)iniparser.lo $(OUTDIR)dictionary.lo
TARGETS = $(OUTDIR)libiniparser.la $(OUTDIR)libiniparser.so

default:	$(TARGETS)

$(OUTDIR)iniparser.lo: $(SRCDIR)iniparser.c
	$(LTCOMPILE.c) -o $(OUTDIR)iniparser.lo $(SRCDIR)iniparser.c

$(OUTDIR)dictionary.lo: $(SRCDIR)dictionary.c
	$(LTCOMPILE.c) -o $(OUTDIR)dictionary.lo $(SRCDIR)dictionary.c

$(OUTDIR)libiniparser.la:	$(LTOBJS)
	@$(LIBTOOL) --tag=CC --mode=link $(CC) $(CFLAGS) -version-info 3 -o $@ $(LTOBJS)

$(OUTDIR)libiniparser.so:	$(OBJS)
	@$(LIBOOL) --mode=link $(SHLD) $(LDSHFLAGS) -o $@.3 $(OBJS) $(LDFLAGS) \
		-Wl,-soname=`basename $@`.3 

install:	$(TARGETS)
	@$(LIBOOL) --mode=install $(INSTALL) $(OUTDIR).libs/libiniparser.a $(DESTDIR)
	@$(LIBOOL) --mode=install $(INSTALL) $(OUTDIR)libiniparser.la $(DESTDIR)
	@$(LIBOOL) --mode=install $(INSTALL) $(OUTDIR)libiniparser.so.3 $(DESTDIR)

clean:
	$(RM) $(OBJS) $(LTOBJS)

veryclean:
	$(RM) $(OBJS) $(LTOBJS) $(TARGETS) 
	$(RM) -r build
	cd test ; $(MAKE) veryclean

check:
	@(cd test ; $(MAKE))
