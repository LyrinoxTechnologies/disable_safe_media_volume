SKIPUNZIP=1
unzip -qjo "$ZIPFILE" -x 'META-INF' 'customize.sh' -d $MODPATH >&2
