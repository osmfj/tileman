AUTOMAKE_OPTIONS = foreign
SUBDIRS = iniparser3.0b

ACLOCAL_AMFLAGS = -I m4

AM_CPPFLAGS = $(FT2_CFLAGS) $(PTHREAD_CFLAGS) $(BOOST_CPPFLAGS) $(ICU_CPPFLAGS)

bin_PROGRAMS = render_expired

renderddir = $(sysconfdir)
render_expired_SOURCES = render_config.h protocol.h dir_utils.c dir_utils.h render_expired.c
render_expired_LDADD = $(PTHREAD_CFLAGS)

