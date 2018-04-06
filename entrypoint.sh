#!/bin/sh
set -e

sed -i -e "s/\${REQ_HOST}/$REQ_HOST/g" /etc/varnish/default.vcl

exec "$@"
