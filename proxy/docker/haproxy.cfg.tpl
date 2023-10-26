global
    log stdout format raw local0 info
    maxconn 4096
    daemon
    lua-load /usr/local/etc/haproxy/retry_on_non_200.lua 
    stats socket /var/run/haproxy.sock mode 660 level admin

defaults
    log global
    mode http
    option httplog
    option dontlognull
    retries 2          # Two retries (three total attempts)
    timeout http-request    25s
    timeout queue           1m
    timeout connect         10s
    timeout client          2m
    timeout server          20s
    timeout http-keep-alive 50s
    timeout check           5s

listen health_check_http_url
    bind :8080
    mode http
    monitor-uri /healthz
    option      dontlognull

frontend http-in
    bind *:80          # Binding on port 80
    default_backend farm

frontend stats
    mode http
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats admin if LOCALHOST

backend farm
    retries 3
    default-server inter 1s fall 1 rise 2
    option httpchk GET /health      # Use the GET method for the /health path
    mode http
    option forwardfor
    option redispatch  # Allow rerouting to a different server on a connection failure
    balance roundrobin
    http-response lua.retry_on_non_200
    server ecs_lb ${lb_dns_name} check on-marked-down shutdown-sessions
    server eks_lb ${eks_name} check on-marked-down shutdown-sessions
    server lambda_backup ${lambda_url} ssl verify none backup  # Lambda trigger endpoint
    #http-request set-header Host SET HEADER
    retry-on all-retryable-errors