#!/bin/sh
set -e

#If curl and Rancher
if hash curl 2>/dev/null && curl rancher-metadata 2>/dev/null >/dev/null; then
  services=$(curl http://rancher-metadata/latest/self/container/links)

  for s in $services; do
    backends=$(curl http://rancher-metadata/latest/services/$s/containers| cut -d'=' -f 2)
    for be in $backends; do
      ip=$(curl http://rancher-metadata/latest/containers/$be/ips/0)

      #Include backend template
      sed -i -e '/%CREATE_BE%/r /be_template' /etc/varnish/default.vcl
      #Add backend to director
      sed -i -e '/\%ADD_BE\%/a bar.add_backend($be);' /etc/varnish/default.vcl
  
      #Insert backend name 
      sed -i -e '/\%BE_NAME\%/$be/g' /etc/varnish/default.vcl 
      #Insert IP address 
      sed -i -e '/\%BE_IP\%/$ip/g' /etc/varnish/default.vcl 
    done
  done
fi

#Remove %CREATE_BE% indicator and %ADD_BE%
sed -i -e 's/\%CREATE_BE\%//g' /etc/varnish/default.vcl
sed -i -e 's/\%ADD_BE\%//g' /etc/varnish/default.vcl


#sed -i -e "s/\${REQ_HOST}/$REQ_HOST/g" /etc/varnish/default.vcl

exec "$@"
