#!/usr/bin/env bash
#
# refresh-cf-cookie.sh — mint a Cloudflare Access (Zero Trust) cookie for the
# on-frontend staging previews (*.stg.int.on.com) and write it as a Playwright
# storage-state file.
#
# Why: the CF Access service token is permanent (lives in ~/.ai-shared/.secrets),
# but the CF_Authorization cookie it issues expires (~24h). Run this to refresh
# the cookie from the token whenever navigation starts hitting the CF login page.
#
# The cookie domain is rewritten to the wildcard parent ".stg.int.on.com" so a
# single cookie works for EVERY PR preview (they sit behind one wildcard CF
# Access app). Never embed the service token as a request header — it would be
# sent to every origin the browser visits. A domain-scoped cookie does not leak.
#
# Usage:
#   refresh-cf-cookie.sh <any-live-stg-url>
#   e.g. refresh-cf-cookie.sh https://on-shop-9455.stg.int.on.com/
#
# Secrets (read from ~/.ai-shared/.secrets, fallback: existing shell env):
#   CLOUDFLARE_ACCESS_CLIENT_ID
#   CLOUDFLARE_ACCESS_CLIENT_SECRET
#
# Output (override with CF_STORAGE_STATE):
#   ~/Library/Application Support/Code/User/cf-stg-storage-state.json
#
# This script prints metadata only — never the token or cookie value.

set -euo pipefail

SECRETS="${HOME}/.ai-shared/.secrets"
if [ -f "$SECRETS" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$SECRETS"
  set +a
fi

: "${CLOUDFLARE_ACCESS_CLIENT_ID:?missing CLOUDFLARE_ACCESS_CLIENT_ID (add it to ~/.ai-shared/.secrets)}"
: "${CLOUDFLARE_ACCESS_CLIENT_SECRET:?missing CLOUDFLARE_ACCESS_CLIENT_SECRET (add it to ~/.ai-shared/.secrets)}"

MINT_URL="${1:-${CF_MINT_URL:-}}"
if [ -z "$MINT_URL" ]; then
  echo "usage: refresh-cf-cookie.sh <live *.stg.int.on.com url>" >&2
  echo "  e.g. refresh-cf-cookie.sh https://on-shop-<PR>.stg.int.on.com/" >&2
  exit 2
fi

OUT="${CF_STORAGE_STATE:-$HOME/Library/Application Support/Code/User/cf-stg-storage-state.json}"
JAR="$(mktemp)"
trap 'rm -f "$JAR"' EXIT

http_code=$(curl -sS -o /dev/null -w '%{http_code}' -c "$JAR" \
  -H "CF-Access-Client-Id: $CLOUDFLARE_ACCESS_CLIENT_ID" \
  -H "CF-Access-Client-Secret: $CLOUDFLARE_ACCESS_CLIENT_SECRET" \
  "$MINT_URL" || true)

if ! grep -q CF_Authorization "$JAR" 2>/dev/null; then
  echo "ERROR: no CF_Authorization cookie issued (http=$http_code)." >&2
  echo "  Check the service token and that <$MINT_URL> is live behind CF Access." >&2
  exit 1
fi

JAR="$JAR" OUT="$OUT" node -e '
  const fs = require("fs");
  const jar = fs.readFileSync(process.env.JAR, "utf8");
  const cookies = [];
  for (const line of jar.split("\n")) {
    if (!line || line.startsWith("#")) continue;
    const p = line.split("\t");
    if (p.length < 7 || p[5] !== "CF_Authorization") continue;
    cookies.push({
      name: "CF_Authorization",
      value: p[6],
      domain: ".stg.int.on.com",
      path: "/",
      expires: Number(p[4]) || -1,
      httpOnly: true,
      secure: true,
      sameSite: "None",
    });
  }
  if (!cookies.length) { console.error("parse failed: CF_Authorization not found in jar"); process.exit(1); }
  fs.mkdirSync(require("path").dirname(process.env.OUT), { recursive: true });
  fs.writeFileSync(process.env.OUT, JSON.stringify({ cookies, origins: [] }, null, 2));
  const c = cookies[0];
  console.log("OK  storage-state -> " + process.env.OUT);
  console.log("    cookie=CF_Authorization domain=" + c.domain +
    " expires=" + (c.expires > 0 ? new Date(c.expires * 1000).toISOString() : "session"));
'

echo "Next: restart the Playwright MCP server so it reloads --storage-state,"
echo "or inject the cookie into the live context with page.context().addCookies()."
