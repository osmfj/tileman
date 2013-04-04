#ifndef RENDER_CONFIG_H
#define RENDER_CONFIG_H

#define MAX_ZOOM 18

// With directory hashing enabled we rewrite the path so that tiles are really stored here instead
#define DIRECTORY_HASH
#define HASH_PATH "/var/opt/tileserver"

// Location of osm.xml file
#define RENDERD_CONFIG "/etc/renderd.conf"
// The XML configuration used if one is not provided
#define XMLCONFIG_DEFAULT "default"
// Maximum number of configurations that mod tile will allow
#define XMLCONFIGS_MAX 10

// Use this to enable meta-tiles which will render NxN tiles at once
// Note: This should be a power of 2 (2, 4, 8, 16 ...)
#define METATILE (8)

#endif
