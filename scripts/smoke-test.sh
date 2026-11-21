#!/usr/bin/env bash
# Smoke test a deployed (or emulated) copy of the site.
# Usage: scripts/smoke-test.sh <base-url>   e.g. https://www.fuori.co.uk or http://localhost:5050
set -euo pipefail

base="${1:?usage: $0 <base-url>}"
base="${base%/}"
failures=0

pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; failures=$((failures + 1)); }

status() { curl -sS -o /dev/null -w '%{http_code}' --retry 3 --retry-all-errors "$1"; }
headers() { curl -sS -D - -o /dev/null --retry 3 --retry-all-errors "$1"; }

check_status() {
  local path="$1" want="$2" got
  got="$(status "$base$path")" || got="error"
  if [[ "$got" == "$want" ]]; then pass "$path -> $got"; else fail "$path -> $got (expected $want)"; fi
}

check_header() {
  local path="$1" pattern="$2"
  if grep -qiE "^$pattern" <<<"$(headers "$base$path")"; then pass "$path has $pattern"; else fail "$path missing $pattern"; fi
}

check_status / 200
check_status /robots.txt 200
check_status /sitemap.xml 200
check_status /favicon.svg 200
check_status /og-image.png 200
check_status /does-not-exist 404

check_header / "content-security-policy: default-src 'self'"
check_header / "strict-transport-security: max-age="
check_header / "x-content-type-options: nosniff"
check_header / "referrer-policy:"
check_header / "permissions-policy:"
check_header /styles.css "cache-control: public, max-age=3600"
check_header /favicon.svg "cache-control: public, max-age=86400"

if ((failures > 0)); then
  echo "$failures check(s) failed against $base"
  exit 1
fi
echo "All checks passed against $base"
