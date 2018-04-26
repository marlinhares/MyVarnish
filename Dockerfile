FROM debian

ENV BE_PORT 80
ENV BE_PATH /
ENV PROBE_TIMEOUT 1s
ENV PROBE_INTERVAL 5s
ENV PROBE_WINDOW 5
ENV PROBE_THRESHOLD 3


RUN apt-get -y update
RUN apt-get -y install varnish curl

COPY varnish.vcl /etc/varnish/varnish_template.vcl
COPY be_template.vcl /etc/varnish/be_template.vcl
COPY runVarnish.sh /etc/varnish/runVarnish.sh

CMD /etc/varnish/runVarnish.sh
