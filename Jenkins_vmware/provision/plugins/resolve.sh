#!/usr/bin/env bash
# MILESTONE 4: resolve/download pinned plugins into STAGING, never the live home.
set -euo pipefail
java_bin=${1:?Java executable required}
manager=${2:?Plugin manager JAR required}
manifest=${3:?Pinned plugin manifest required}
stage=${4:?Staging directory required}
core_version=${5:?Jenkins version required}
[[ "$stage" == /var/cache/jenkins-plugin-manager/* ]] || { echo 'Expected a staging directory' >&2; exit 1; }
mkdir -p "$stage/plugins"
export CACHE_DIR=/var/cache/jenkins-plugin-manager/metadata
"$java_bin" -jar "$manager" \
  --war /usr/share/java/jenkins.war --jenkins-version "$core_version" \
  --plugin-file "$manifest" --plugin-download-directory "$stage/plugins" \
  --latest false --list 2>&1 | tee "$stage/resolution.log"
