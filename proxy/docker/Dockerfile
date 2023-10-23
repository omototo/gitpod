FROM haproxy:latest
USER root
RUN apt-get update && apt-get install netcat -y

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY retry_on_non_200.lua /usr/local/etc/haproxy/retry_on_non_200.lua

USER root
RUN chmod 644 /usr/local/etc/haproxy/haproxy.cfg
RUN chmod 644 /usr/local/etc/haproxy/retry_on_non_200.lua

