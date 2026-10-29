#!/usr/bin/env bash
# Writes the build stamp the start screen shows, so the version running on a
# device can be matched against a commit without guessing.
#
# It exists because "I pulled and nothing changed" cost this project several
# rounds: there was no way to tell, from a screenshot, which commit was
# running. Now the start screen says so.
set -euo pipefail
cd "$(dirname "$0")/.."
printf '%s %s\n' "$(git rev-parse --short HEAD)" "$(date -u +%Y-%m-%d)" \
  > resources/build_stamp.txt
cat resources/build_stamp.txt
