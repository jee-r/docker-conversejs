# docker-conversejs

Docker image serving [ConverseJS](https://conversejs.org/) via nginx. The `index.html` and nginx config are generated at container startup from environment variables.

## Images

| Registry | Image |
|---|---|
| GitHub Container Registry | `ghcr.io/jee-r/conversejs` |

### Tags

| Tag | Description |
|---|---|
| `latest` | Latest stable build from `main` |
| `x.y.z`, `x.y`, `x` | Pinned to a specific ConverseJS version — see [releases](https://github.com/conversejs/converse.js/releases) |
| `dev` | Build from `dev` branch |
| `<short-sha>` | Immutable build reference |

## Usage

### docker-compose

The `docker-compose.yml` is not committed to the repository (it's gitignored). Copy the example below to get started:

```yaml
services:
  conversejs:
    image: ghcr.io/jee-r/conversejs:latest
    container_name: conversejs
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - APP_TITLE=My Chat
      # Authentication
      - CONVERSEJS_AUTHENTICATION=anonymous
      - CONVERSEJS_AUTO_LOGIN=true
      - CONVERSEJS_AUTO_RECONNECT=true
      # XMPP connection
      - CONVERSEJS_JID=anon.example.org
      - CONVERSEJS_BOSH_SERVICE_URL=https://xmpp.example.org/http-bind
      # - CONVERSEJS_WEBSOCKET_URL=wss://xmpp.example.org/ws
      - CONVERSEJS_REGISTRATION_DOMAIN=anon.example.org
      # Rooms
      - CONVERSEJS_AUTO_JOIN_ROOMS=general@conference.example.org
      # Nickname
      # - NICKNAME_PREFIX=anon
      # UI
      # - CONVERSEJS_THEME=nord
      # - CONVERSEJS_DARK_THEME=nord
      # Session
      - CONVERSEJS_SINGLETON=true
      - CONVERSEJS_KEEPALIVE=true
      - CONVERSEJS_ALLOW_LOGOUT=true
      - CONVERSEJS_CLEAR_CACHE_ON_LOGOUT=true
      - CONVERSEJS_HIDE_OFFLINE_USERS=true
    volumes:
      - /etc/localtime:/etc/localtime:ro
```

### podman run

```sh
podman run -d \
  -p 8080:8080 \
  -e CONVERSEJS_AUTHENTICATION=anonymous \
  -e CONVERSEJS_AUTO_LOGIN=true \
  -e CONVERSEJS_JID=anon.example.org \
  -e CONVERSEJS_BOSH_SERVICE_URL=https://xmpp.example.org/http-bind \
  ghcr.io/jee-r/conversejs:latest
```

## Environment variables

### converse.js options — `CONVERSEJS_` prefix

Any [converse.js configuration option](https://conversejs.org/docs/html/configuration.html) can be set by prefixing its name with `CONVERSEJS_` in uppercase:

```
CONVERSEJS_<OPTION_NAME_UPPERCASE>=value
```

Examples:

```yaml
- CONVERSEJS_AUTHENTICATION=anonymous
- CONVERSEJS_AUTO_LOGIN=true
- CONVERSEJS_BOSH_SERVICE_URL=https://xmpp.example.org/http-bind
- CONVERSEJS_LOGLEVEL=debug
```

Booleans and numbers are passed as-is; everything else is automatically quoted as a string. For options that expect arrays, objects, or regex, use [`CONVERSE_EXTRA_CONFIG`](#converse_extra_config).

The image sets one opinionated default: `CONVERSEJS_VIEW_MODE=fullscreen`. All other options defer to converse.js defaults when unset.

### Container-specific variables

| Variable | Default | Description |
|---|---|---|
| `APP_TITLE` | `ConverseJS` | Browser tab title (`<title>` tag) |
| `NICKNAME_PREFIX` | — | If set, generates a unique per-browser nickname via localStorage (`<prefix>_<uuid8>`) |

### `CONVERSE_EXTRA_CONFIG`

Inject raw JS properties into `converse.initialize({...})` for options that require complex types (arrays, objects, regex) not expressible as a plain string. Supports YAML multiline:

```yaml
environment:
  CONVERSE_EXTRA_CONFIG: |
    auto_join_rooms: ['general@conference.example.org'],
    visible_toolbar_buttons: {emoji: false},
    connection_options: {ws_opts: {timeout: 60000}},
    blacklisted_plugins: ['converse-omemo'],
```

### `CUSTOM_HTML`

Mount your own `index.html` and point `CUSTOM_HTML` to its path inside the container. The nginx config and well-known files are still generated normally — only the HTML template is skipped.

```yaml
volumes:
  - ./my-index.html:/custom/index.html:ro
environment:
  - CUSTOM_HTML=/custom/index.html
```

### XMPP auto-discovery (well-known)

When `CONVERSEJS_BOSH_SERVICE_URL` or `CONVERSEJS_WEBSOCKET_URL` is set, the container automatically generates and serves:

- `/.well-known/host-meta` — XRD XML (`application/xrd+xml`)
- `/.well-known/host-meta.json` — JRD JSON (`application/jrd+json`)

No volume mount or extra configuration needed. Only the links for the URLs that are set are included.

Example output with both URLs set:

```xml
<?xml version="1.0" encoding="utf-8"?>
<XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0">
    <link rel="urn:xmpp:alt-connections:xbosh" href="https://xmpp.example.org/http-bind" />
    <link rel="urn:xmpp:alt-connections:websocket" href="wss://xmpp.example.org/ws" />
</XRD>
```

## Build

```sh
# Build locally with podman
podman build --network host -t conversejs .

# Override ConverseJS version
podman build --network host --build-arg CONVERSEJS_VERSION=13.0.1 -t conversejs .
```

The ConverseJS release archive is downloaded from GitHub at build time. The version is controlled by the `CONVERSEJS_VERSION` build arg — see [converse.js releases](https://github.com/conversejs/converse.js/releases) for available versions.

## CI

Two GitHub Actions workflows are provided:

| Workflow | Trigger | Action |
|---|---|---|
| `deploy.yaml` | Push to `main`/`dev`, weekly schedule, manual | Build multi-arch image (`amd64`, `arm64`, `armv7`) and push to GHCR |
| `build_test.yaml` | Push to feature branches, PRs to `main`/`dev` | Build only, no push |
