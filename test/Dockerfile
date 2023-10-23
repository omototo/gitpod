FROM haproxy:latest

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY retry_on_non_200.lua /usr/local/etc/haproxy/retry_on_non_200.lua
COPY set_host.lua /usr/local/etc/haproxy/set_host.lua
COPY xip.io.pem /usr/local/etc/haproxy/xip.io.pem

USER root
RUN chmod 644 /usr/local/etc/haproxy/haproxy.cfg
RUN chmod 644 /usr/local/etc/haproxy/retry_on_non_200.lua
RUN chmod 644 /usr/local/etc/haproxy/set_host.lua
RUN chmod 644 /usr/local/etc/haproxy/xip.io.pem


EXPOSE 8404 9000 8080

