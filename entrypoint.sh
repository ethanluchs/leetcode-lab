#!/usr/bin/env bash
set -euo pipefail

# /work is a bind mount from the host and starts empty. Copy the problems
# baked into the image across on first run only, so student edits survive
# restarts and are never clobbered.
if [ ! -d /work/leetcode ]; then
  echo "First run -- seeding problems into ./work ..."
  cp -r /opt/seed/leetcode /work/leetcode
  echo "Ready: $(find /work/leetcode -maxdepth 1 -mindepth 1 -type d | wc -l) problems in ./work/leetcode"
  echo
fi

exec "$@"
