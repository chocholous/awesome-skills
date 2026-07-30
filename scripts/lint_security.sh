#!/usr/bin/env bash
# lint_security.sh — fail if any file under skills/ contains a hardcoded
# Apify API token. Real tokens always start with the "apify_api_" prefix
# followed by 30+ alphanumeric characters; we flag 20+ to catch truncated
# copies while letting short documentation placeholders (e.g. a trailing
# "xxx") pass.
#
# Skills are executed by other people's agents with their own credentials;
# a committed token is a leaked secret. See SECURITY.md.
#
# Exit 0 if no token is found, exit 1 if any violation is found.
# Compatible with bash 3.2+ (macOS) and bash 5 (GitHub Actions runners).

set -euo pipefail

if [ ! -d skills ]; then
  echo "lint: skills/ directory not found — run from the repository root." >&2
  exit 2
fi

# grep exits 0 on match (= violation found), 1 on no match (= clean), >1 on error.
set +e
MATCHES=$(grep -rEn 'apify_api_[A-Za-z0-9]{20,}' skills/)
STATUS=$?
set -e

if [ "$STATUS" -gt 1 ]; then
  echo "lint: grep failed while scanning skills/ (exit $STATUS)" >&2
  exit "$STATUS"
fi

if [ "$STATUS" -eq 1 ]; then
  echo "lint: security checks passed."
  exit 0
fi

FAIL=0
while IFS= read -r match; do
  [ -z "$match" ] && continue
  file="${match%%:*}"
  rest="${match#*:}"
  lineno="${rest%%:*}"
  echo "lint: $file:$lineno: hardcoded Apify token — remove it; skills must never contain credentials (see SECURITY.md)"
  FAIL=$(( FAIL + 1 ))
done <<< "$MATCHES"

echo ""
echo "lint: $FAIL violation(s) found."
echo "      Reference tokens via the APIFY_TOKEN environment variable instead,"
echo "      and rotate any token that was committed — treat it as leaked."
echo "      See SECURITY.md for the full policy."
exit 1
