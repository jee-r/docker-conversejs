#!/bin/sh
set -e

HTML_OUTPUT=/usr/share/nginx/html/index.html
NGINX_CONF=/etc/nginx/conf.d/default.conf
WELL_KNOWN_DIR=/usr/share/nginx/html/.well-known

# Auto-detect type: bool/number → literal, else → quoted string
opt_mixed() {
    [ -z "$2" ] && return 0
    case "$2" in
        true|false|[0-9]*) CFG="${CFG}
    ${1}: ${2}," ;;
        *) CFG="${CFG}
    ${1}: \"${2}\"," ;;
    esac
}

# ── nginx ──────────────────────────────────────────────────────────────────

WELL_KNOWN_BLOCK=""
if [ -n "$CONVERSEJS_BOSH_SERVICE_URL" ] || [ -n "$CONVERSEJS_WEBSOCKET_URL" ]; then
    WELL_KNOWN_BLOCK="
    location = /.well-known/host-meta {
        default_type application/xrd+xml;
    }

    location = /.well-known/host-meta.json {
        default_type application/jrd+json;
    }"
fi

cat > "$NGINX_CONF" << NGINX
server {
    listen      8080;
    server_name localhost;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~* \.(ttf|ttc|otf|eot|woff|woff2|css|js)$ {
        add_header Access-Control-Allow-Origin "*";
    }
${WELL_KNOWN_BLOCK}
}
NGINX

# ── well-known ─────────────────────────────────────────────────────────────

if [ -n "$CONVERSEJS_BOSH_SERVICE_URL" ] || [ -n "$CONVERSEJS_WEBSOCKET_URL" ]; then
    mkdir -p "$WELL_KNOWN_DIR"

    XML_LINKS=""
    [ -n "$CONVERSEJS_BOSH_SERVICE_URL" ] && XML_LINKS="${XML_LINKS}
    <link rel=\"urn:xmpp:alt-connections:xbosh\" href=\"${CONVERSEJS_BOSH_SERVICE_URL}\" />"
    [ -n "$CONVERSEJS_WEBSOCKET_URL" ]    && XML_LINKS="${XML_LINKS}
    <link rel=\"urn:xmpp:alt-connections:websocket\" href=\"${CONVERSEJS_WEBSOCKET_URL}\" />"

    cat > "${WELL_KNOWN_DIR}/host-meta" << XML
<?xml version="1.0" encoding="utf-8"?>
<XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0">
${XML_LINKS}
</XRD>
XML

    JSON_LINKS=""
    [ -n "$CONVERSEJS_BOSH_SERVICE_URL" ] && \
        JSON_LINKS="        {\"rel\": \"urn:xmpp:alt-connections:xbosh\", \"href\": \"${CONVERSEJS_BOSH_SERVICE_URL}\"}"
    if [ -n "$CONVERSEJS_WEBSOCKET_URL" ]; then
        [ -n "$JSON_LINKS" ] && JSON_LINKS="${JSON_LINKS},"
        JSON_LINKS="${JSON_LINKS}
        {\"rel\": \"urn:xmpp:alt-connections:websocket\", \"href\": \"${CONVERSEJS_WEBSOCKET_URL}\"}"
    fi

    cat > "${WELL_KNOWN_DIR}/host-meta.json" << JSON
{
    "links": [
${JSON_LINKS}
    ]
}
JSON
fi

# ── index.html ─────────────────────────────────────────────────────────────

# localStorage nickname generation with prefix
NICKNAME_JS=""
if [ -n "$NICKNAME_PREFIX" ]; then
    NICKNAME_JS="
    const storedNick = localStorage.getItem('nickname');
    const nickname = storedNick || '${NICKNAME_PREFIX}_' + self.crypto.randomUUID().slice(0, 8);
    if (!storedNick) localStorage.setItem('nickname', nickname);"
fi

# ── converse.initialize() options ──────────────────────────────────────────

CFG="    assets_path: \"/package/dist/\","

# Inject all CONVERSEJS_* env vars — key is lowercased option name
for _env in $(env | grep '^CONVERSEJS_' | cut -d= -f1 | sort || true); do
    _key=$(echo "${_env#CONVERSEJS_}" | tr '[:upper:]' '[:lower:]')
    _val=$(printenv "$_env")
    opt_mixed "$_key" "$_val"
done

# Raw JS snippet for complex options (objects, arrays, regex)
[ -n "$CONVERSE_EXTRA_CONFIG" ] && CFG="${CFG}
    ${CONVERSE_EXTRA_CONFIG}"

if [ -n "$CUSTOM_HTML" ]; then
    cp "$CUSTOM_HTML" "$HTML_OUTPUT"
else

cat > "$HTML_OUTPUT" << HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" type="image/svg+xml" href="/favicon.svg">
    <title>${APP_TITLE:-ConverseJS}</title>
    <link rel="stylesheet" type="text/css" media="screen" href="/package/dist/converse.min.css">
    <script src="/package/dist/converse.min.js" charset="utf-8"></script>
</head>
<body>
    <div id="conversejs-bg"></div>
</body>
<script>
${NICKNAME_JS}
    converse.initialize({
${CFG}
    });
</script>
</html>
HTML

fi

exec "$@"
