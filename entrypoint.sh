#!/bin/sh
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid
# rm -rf /app/tmp/*
# export SECRET_KEY_BASE=`rake secret`
# $HOME/.yarn/bin/yarn install --pure-lockfile
# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"