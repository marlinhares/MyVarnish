FROM debian

RUN apt-get -y update
RUN apt-get -y install varnish

CMD /usr/sbin/varnishd -j unix,user=varnish -F -f /etc/varnish/default.vcl -a 0.0.0.0:80 -T 0.0.0.0:6082 -s malloc,1g
