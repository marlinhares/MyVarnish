FROM debian

RUN apt-get -y update
RUN apt-get -y install varnish curl

COPY varnish.vcl /etc/varnish/template.vcl
COPY be_template.vcl /etc/varnish/be_template.vcl

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD /usr/sbin/varnishd -j unix,user=varnish -F -f /etc/varnish/default.vcl -a 0.0.0.0:80 -T 0.0.0.0:6082 -s malloc,1g
