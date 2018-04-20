#!/bin/sh
set -e

#If curl and Rancher
if hash curl 2>/dev/null && curl rancher-metadata 2>/dev/null >/dev/null; then
  services=$(curl http://rancher-metadata/latest/self/service/links)
  echo "Servicos encontrados:"
  echo $services

  services_san=$(echo $services | sed -e "s/.*%2F\(.*\)/\1/g")
  for s in $services_san; do
    kind=$(curl http://rancher-metadata/latest/services/$s/kind)
    case $kind in
      service)
        echo "Criando backends para $s ..."
        backends=$(curl http://rancher-metadata/latest/services/$s/containers| cut -d'=' -f 2)
          for be in $backends; do
            be_san=$(echo $be | tr '-' '_')
            echo "Backend $be_san ..."
            ip=$(curl http://rancher-metadata/latest/containers/$be/ips/0)

            #Include backend template
            sed -i -e "/%CREATE_BE%/r /be_template" /etc/varnish/default.vcl
            #Add backend to director
            sed -i -e "s/\%ADD_BE\%/bar.add_backend($be_san);\n    \%ADD_BE\%/g" /etc/varnish/default.vcl 

            #Insert backend name 
            sed -i -e "s/\%BE_NAME\%/$be_san/g" /etc/varnish/default.vcl 
            #Insert IP address 
            sed -i -e "s/\%BE_IP\%/$ip/g" /etc/varnish/default.vcl 
          done
        ;;
      externalService)
        echo "Criando backends para $s ..."
        backends=$(curl http://rancher-metadata/latest/services/$s/external_ips)
          for be in $backends; do
            s_san=$(echo $s | tr '-' '_')
            echo "Backend $s_san\_$be ..."
            ip=$(curl http://rancher-metadata/latest/services/$s/external_ips/$be)

            #Include backend template
            sed -i -e "/%CREATE_BE%/r /be_template" /etc/varnish/default.vcl
            #Add backend to director
            sed -i -e "s/\%ADD_BE\%/bar.add_backend($s_san\_$be);\n    \%ADD_BE\%/g" /etc/varnish/default.vcl
 
            #Insert backend name 
            sed -i -e "s/\%BE_NAME\%/$s_san\_$be/g" /etc/varnish/default.vcl
            #Insert IP address 
            sed -i -e "s/\%BE_IP\%/$ip/g" /etc/varnish/default.vcl
          done
        ;;       
      *)
          echo "Servico $s não será considerado"
        ;;
    esac
  done
fi

#Remove %CREATE_BE% indicator and %ADD_BE%
sed -i -e "s/\%CREATE_BE\%//g" /etc/varnish/default.vcl
sed -i -e "s/\%ADD_BE\%//g" /etc/varnish/default.vcl


#sed -i -e "s/\${REQ_HOST}/$REQ_HOST/g" /etc/varnish/default.vcl

exec "$@"
