#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.61])
AX_CONFIG_NICE
AC_INIT(tilecache, 0.1, https://github.com/osmfj/tileproxy)
AM_INIT_AUTOMAKE(tileproxy,0.1)
LT_INIT
AC_CONFIG_SRCDIR([render_expired.c])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])

# Checks for programs.
AC_PROG_CXX
AC_PROG_CC
AC_PROG_CC_C99

# Checks for libraries.

# Checks for header files.
AC_CHECK_HEADERS([fcntl.h limits.h stdint.h stdlib.h string.h sys/time.h syslog.h unistd.h utime.h paths.h sys/cdefs.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_INLINE
AC_TYPE_MODE_T
AC_TYPE_SIZE_T
AC_TYPE_UINT16_T
AC_TYPE_UINT32_T
AC_TYPE_UINT64_T

# Checks for library functions.
AC_FUNC_MALLOC
AC_FUNC_MKTIME

AX_PTHREAD(,[AC_MSG_ERROR([no])])
AC_SEARCH_LIBS(pow,m)
AC_CHECK_FUNCS([bzero gettimeofday memset mkdir pow strchr strdup strerror strrchr strstr strtol strtoul utime],[],[AC_MSG_ERROR([One of the required functions was not found])])

AC_CONFIG_FILES(Makefile iniparser3.0b/Makefile)
AC_OUTPUT
