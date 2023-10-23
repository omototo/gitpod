#!/bin/bash

# Start SSM Agent
/usr/bin/amazon-ssm-agent &

# Start HAProxy
exec /docker-entrypoint.sh haproxy "$@"
