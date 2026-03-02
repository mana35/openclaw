#!/bin/sh
set -e

CONFIG_DIR="${HOME}/.openclaw"
CONFIG_FILE="${CONFIG_DIR}/config.json"

mkdir -p "$CONFIG_DIR"

# Ensure config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo '{}' > "$CONFIG_FILE"
fi

# Configure Control UI allowed origins for non-loopback (LAN) bind.
# Set OPENCLAW_CONTROL_UI_ALLOWED_ORIGINS as a JSON array, e.g.:
#   OPENCLAW_CONTROL_UI_ALLOWED_ORIGINS=["https://openclaw.example.com"]
# Or set OPENCLAW_HOST_HEADER_FALLBACK=true to use Host-header origin fallback
# (safe behind a trusted reverse proxy like Traefik/nginx).
if [ -n "$OPENCLAW_CONTROL_UI_ALLOWED_ORIGINS" ]; then
  node -e "
    const fs = require('fs');
    const p = '${CONFIG_FILE}';
    const cfg = JSON.parse(fs.readFileSync(p, 'utf8'));
    cfg.gateway = cfg.gateway || {};
    cfg.gateway.controlUi = cfg.gateway.controlUi || {};
    cfg.gateway.controlUi.allowedOrigins = JSON.parse(process.env.OPENCLAW_CONTROL_UI_ALLOWED_ORIGINS);
    fs.writeFileSync(p, JSON.stringify(cfg, null, 2));
  "
elif [ "${OPENCLAW_HOST_HEADER_FALLBACK}" = "true" ]; then
  node -e "
    const fs = require('fs');
    const p = '${CONFIG_FILE}';
    const cfg = JSON.parse(fs.readFileSync(p, 'utf8'));
    cfg.gateway = cfg.gateway || {};
    cfg.gateway.controlUi = cfg.gateway.controlUi || {};
    cfg.gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback = true;
    fs.writeFileSync(p, JSON.stringify(cfg, null, 2));
  "
fi

exec "$@"
