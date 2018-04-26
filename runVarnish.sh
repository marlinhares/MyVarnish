#!/bin/sh
set -e

BE_TEMPLATE=/etc/varnish/be_template.vcl
VARNISH_CONFIG=/etc/varnish/default.vcl
VARNISH_NEW=/etc/varnish/varnish_new.vcl
VARNISH_TEMPLATE=/etc/varnish/varnish_template.vcl

genConfig () {
cp $VARNISH_TEMPLATE $VARNISH_NEW
#If curl and Rancher
if hash curl 2>/dev/null && curl rancher-metadata 2>/dev/null >/dev/null; then
  services=$(curl http://rancher-metadata/latest/self/service/links 2>/dev/null)
  echo "Servicos encontrados:"
  echo $services

  services_san=$(echo $services | sed -e "s/.*%2F\(.*\)/\1/g")
  for s in $services_san; do
    kind=$(curl http://rancher-metadata/latest/services/$s/kind 2>/dev/null)
    case $kind in
      service)
        echo "Criando backends para $s ..."
        backends=$(curl http://rancher-metadata/latest/services/$s/containers 2>/dev/null| cut -d'=' -f 2)
          for be in $backends; do
            be_san=$(echo $be | tr '-' '_')
            echo "Backend $be_san ..."
            ip=$(curl http://rancher-metadata/latest/containers/$be/ips/0  2>/dev/null)

            #Include backend template
            sed -i -e "/%CREATE_BE%/r $BE_TEMPLATE" $VARNISH_NEW
            #Add backend to director
            sed -i -e "s/\%ADD_BE\%/bar.add_backend($be_san);\n    \%ADD_BE\%/g" $VARNISH_NEW 

            #Insert backend name 
            sed -i -e "s/\%BE_NAME\%/$be_san/g" $VARNISH_NEW 
            #Insert IP address 
            sed -i -e "s/\%BE_IP\%/$ip/g" $VARNISH_NEW 
          done
        ;;
      externalService)
        echo "Criando backends para $s ..."
        backends=$(curl http://rancher-metadata/latest/services/$s/external_ips 2>/dev/null)
          for be in $backends; do
            s_san=$(echo $s | tr '-' '_')
            echo "Backend $s_san\_$be ..."
            ip=$(curl http://rancher-metadata/latest/services/$s/external_ips/$be 2>/dev/null)

            #Include backend template
            sed -i -e "/%CREATE_BE%/r $BE_TEMPLATE" $VARNISH_NEW
            #Add backend to director
            sed -i -e "s/\%ADD_BE\%/bar.add_backend($s_san\_$be);\n    \%ADD_BE\%/g" $VARNISH_NEW
 
            #Insert backend name 
            sed -i -e "s/\%BE_NAME\%/$s_san\_$be/g" $VARNISH_NEW
            #Insert IP address 
            sed -i -e "s/\%BE_IP\%/$ip/g" $VARNISH_NEW
          done
        ;;       
      *)
          echo "Servico $s não será considerado"
        ;;
    esac
  done
fi

#Remove %CREATE_BE% indicator and %ADD_BE%
sed -i -e "s/\%CREATE_BE\%//g" $VARNISH_NEW
sed -i -e "s/\%ADD_BE\%//g" $VARNISH_NEW

#Temporary port mapping to backend
sed -i -e "s/\%BE_PORT\%/${BE_PORT}/g" $VARNISH_NEW
sed -i -e "s|\%BE_PATH\%|${BE_PATH}|g" $VARNISH_NEW
sed -i -e "s|\%PROBE_TIMEOUT\%|${PROBE_TIMEOUT}|g" $VARNISH_NEW
sed -i -e "s|\%PROBE_INTERVAL\%|${PROBE_INTERVAL}|g" $VARNISH_NEW
sed -i -e "s|\%PROBE_WINDOW\%|${PROBE_WINDOW}|g" $VARNISH_NEW
sed -i -e "s|\%PROBE_THRESHOLD\%|${PROBE_THRESHOLD}|g" $VARNISH_NEW
}

reloadVarnish () {
# Generate a unique timestamp ID for this version of the VCL
TIME=$(date +%s)

# Copy new to default
cp $VARNISH_NEW $VARNISH_CONFIG

# Load the file into memory
ReloadCmd="varnishadm -S /etc/varnish/secret vcl.load varnish_$TIME $VARNISH_CONFIG"

# Active this Varnish config
StartCmd="varnishadm -S /etc/varnish/secret vcl.use varnish_$TIME"

#Discard
getColdCmd="varnishadm -S /etc/varnish/secret vcl.list" 
DiscardCmd="varnishadm -S /etc/varnish/secret vcl.discard "

$ReloadCmd
$StartCmd

echo "Lista de vcl a apagar:"
discard=$($getColdCmd | grep "cold" | cut -d' ' -f4)
echo Apagando $discard
for d in $discard; do
  $DiscardCmd $d
done
}

/usr/sbin/varnishd -j unix,user=varnish -F -f /etc/varnish/default.vcl -a 0.0.0.0:80 -T 0.0.0.0:6082 -s malloc,1g > /dev/stdout 2>/dev/stderr &
# Wait for varnish to go up
sleep 5

while [ 1 ]
do
  #Gera nova configuração
  genConfig
 
  #Compara hashs dos arquivos
  oldHash=$(md5sum $VARNISH_CONFIG | cut -d' ' -f1)
  newHash=$(md5sum $VARNISH_NEW | cut -d' ' -f1)

  echo "Gerada configuração - $oldHash:$newHash"
  #Caso diferente - nova configuração
  if [ $oldHash != $newHash ]; then
    echo "Aplicando nova configuração ..." 

    #Chama reloadVarnish.sh para carregar a nova configuração em varnish_new.vcl
    reloadVarnish

  fi

 
  sleep 10 
done
