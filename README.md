# docker-conversejs

Docker image serving [ConverseJS](https://conversejs.org/) via nginx. The `index.html` and nginx config are generated at container startup from environment variables.

Most converse.js options are exposed as environment variables. Options that accept arrays of strings use a comma-separated value. Options that accept a boolean or an array of strings are noted `mixed-array`. Raw JS regex literals can be passed directly (e.g. `/pattern/flags`). For complex types (objects, arrays of objects) that cannot be expressed as a single string, use [`CONVERSE_EXTRA_CONFIG`](#converse_extra_config). Truly unsupported options (require structured data): `connection_options`, `emoji_categories`, `visible_toolbar_buttons`, `push_app_servers`, `oauth_providers`, `muc_hats`.

## Images

| Registry | Image |
|---|---|
| GitHub Container Registry | `ghcr.io/jee-r/conversejs` |
| Docker Hub | `jee-r/conversejs` |

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
      - AUTHENTICATION=anonymous
      - AUTO_LOGIN=true
      - AUTO_RECONNECT=true
      # XMPP connection
      - JID=anon.example.org
      - BOSH_SERVICE_URL=https://xmpp.example.org/http-bind
      # - WEBSOCKET_URL=wss://xmpp.example.org/ws
      - REGISTRATION_DOMAIN=anon.example.org
      # Rooms
      - AUTO_JOIN_ROOMS=general@conference.example.org
      # - MUC_SHOW_LOGS_BEFORE_JOIN=false
      # - MUC_FETCH_MEMBERS="member","admin","owner"
      # Nickname
      # - NICKNAME_PREFIX=anon
      # - DEFAULT_NICKNAME=
      # UI
      - VIEW_MODE=fullscreen
      # - THEME=nordic
      # - DARK_THEME=nordic
      # Session
      - SINGLETON=true
      - KEEPALIVE=true
      - ALLOW_LOGOUT=true
      - CLEAR_CACHE_ON_LOGOUT=true
      - SHOW_ONLY_ONLINE_USERS=true
      - HIDE_OFFLINE_USERS=true
    volumes:
      - /etc/localtime:/etc/localtime:ro
```

### podman run

```sh
podman run -d \
  -p 8080:8080 \
  -e AUTHENTICATION=anonymous \
  -e AUTO_LOGIN=true \
  -e JID=anon.example.org \
  -e BOSH_SERVICE_URL=https://xmpp.example.org/http-bind \
  ghcr.io/jee-r/conversejs:latest
```

## Environment variables

All variables are optional. If unset or empty, the option is omitted and converse.js uses its own default.

Variables marked `mixed` accept either a boolean (`true`/`false`) or a string value — see the [converse.js docs](https://conversejs.org/docs/html/configuration.html) for valid values.

### General

| Variable | Default | Description |
|---|---|---|
| `APP_TITLE` | `ConverseJS` | Browser tab title |
| `VIEW_MODE` | `fullscreen` | `fullscreen`, `overlayed`, or `embedded` |
| `LOGLEVEL` | `info` | `debug`, `info`, `warn`, `error`, or `fatal` |
| `I18N` | auto | Language/locale code (e.g. `fr`, `de`, `es`) |
| `LOCALES` | — | Comma-separated locales to load (empty = all bundled) |
| `STRICT_PLUGIN_DEPENDENCIES` | `false` | Raise error if plugin overrides non-existent object |

### Connection

| Variable | Default | Description |
|---|---|---|
| `BOSH_SERVICE_URL` | — | BOSH endpoint (e.g. `https://xmpp.example.org/http-bind`) |
| `WEBSOCKET_URL` | — | WebSocket endpoint (e.g. `wss://xmpp.example.org/ws`) |
| `JID` | — | XMPP JID or domain. For anonymous auth, set to the anonymous domain |
| `PRIORITY` | `0` | XMPP resource priority |
| `PING_INTERVAL` | `60` | Seconds between server pings |
| `STANZA_TIMEOUT` | `20000` | Milliseconds before a stanza times out |
| `ENABLE_SMACKS` | `true` | XEP-0198 Stream Management |
| `SMACKS_MAX_UNACKED_STANZAS` | `5` | Stanzas before requesting acknowledgement |
| `DISCOVER_CONNECTION_METHODS` | `true` | Use XEP-0156 to auto-discover BOSH/WS URLs |
| `CREDENTIALS_URL` | — | URL to fetch auth credentials from |
| `PREBIND_URL` | — | URL to fetch BOSH RID/SID tokens (for `prebind` auth) |
| `CSI_WAITING_TIME` | `0` | Seconds of inactivity before sending XEP-0352 inactive state |
| `REUSE_SCRAM_KEYS` | `true` | Store SCRAM keys for automatic login |

### Authentication

| Variable | Default | Description |
|---|---|---|
| `AUTHENTICATION` | `login` | `login`, `anonymous`, `external`, or `prebind` |
| `AUTO_LOGIN` | `false` | Skip login form and connect automatically |
| `AUTO_RECONNECT` | `false` | Reconnect automatically on disconnect |
| `AUTO_SUBSCRIBE` | `false` | Auto-accept incoming contact requests |
| `REGISTRATION_DOMAIN` | — | Domain for in-band registration (XEP-0077) |
| `ALLOW_REGISTRATION` | `true` | Show in-band registration option |
| `DEFAULT_DOMAIN` | — | Pre-fill domain in login form |
| `LOCKED_DOMAIN` | — | Force login to this domain only |
| `DOMAIN_PLACEHOLDER` | — | Placeholder text in domain input |
| `SHOW_CONNECTION_URL_INPUT` | `false` | Show connection URL input in login form |
| `XMPP_PROVIDERS_URL` | — | URL for XMPP provider list |
| `PROVIDERS_LINK` | — | Link to public XMPP server directory |
| `AUTOCOMPLETE_PROVIDERS_URL` | — | URL for provider domain autocomplete |

### Session / Storage

| Variable | Default | Description |
|---|---|---|
| `KEEPALIVE` | `true` | Restore previous session on page reload |
| `CLEAR_CACHE_ON_LOGOUT` | `false` | Wipe all local data on logout |
| `CLEAR_MESSAGES_ON_RECONNECTION` | `false` | Clear cached messages on reconnect |
| `PERSISTENT_STORE` | `IndexedDB` | `IndexedDB`, `localStorage`, or `sessionStorage` |
| `IDLE_PRESENCE_TIMEOUT` | `300` | Seconds before considered idle (XEP-0319) |
| `AUTO_AWAY` | `0` | Seconds before presence becomes `away` (0 = disabled) |
| `AUTO_XA` | `0` | Seconds before presence becomes `xa` (0 = disabled) |
| `SYNCHRONIZE_AVAILABILITY` | `true` | Sync status with other clients. `mixed`: `true`, `false`, `'manual'` |

### Presence / Roster

| Variable | Default | Description |
|---|---|---|
| `ALLOW_CONTACT_REQUESTS` | `true` | Allow adding contacts |
| `ALLOW_CONTACT_REMOVAL` | `true` | Allow removing contacts |
| `ALLOW_NON_ROSTER_MESSAGING` | `false` | Receive messages from non-contacts |
| `ROSTER_GROUPS` | `true` | Show roster groups |
| `SHOW_SELF_IN_ROSTER` | `true` | Show own JID in contacts list |
| `ENABLE_ROSTER_VERSIONING` | `true` | Use roster versioning (XEP-0237) |
| `HIDE_OFFLINE_USERS` | `false` | Hide offline users from roster |
| `LAZY_LOAD_VCARDS` | `true` | Fetch vCards lazily |

### Rooms (MUC)

| Variable | Default | Description |
|---|---|---|
| `AUTO_JOIN_ROOMS` | — | Comma-separated MUC JIDs to join on login |
| `AUTO_JOIN_PRIVATE_CHATS` | — | Comma-separated JIDs to open private chats with on login |
| `AUTO_JOIN_ON_INVITE` | `false` | Auto-join rooms on invite without confirmation |
| `AUTO_LIST_ROOMS` | `false` | Fetch room list from server |
| `MUC_DOMAIN` | — | Default MUC domain |
| `MUC_GROUPED_BY_DOMAIN` | `false` | Group rooms by domain in the list |
| `MUC_HISTORY_MAX_STANZAS` | — | Max messages shown when entering a room |
| `MUC_INSTANT_ROOMS` | `true` | Create rooms instantly without configuration |
| `MUC_NICKNAME_FROM_JID` | `false` | Use JID node as MUC nickname |
| `AUTO_REGISTER_MUC_NICKNAME` | `unregister` | Auto-register nickname. `mixed`: `true`, `false`, `'unregister'` |
| `MUC_SHOW_LOGS_BEFORE_JOIN` | `false` | Show history before entering a room |
| `MUC_FETCH_MEMBERS` | `true` | Fetch member list on join. `mixed`: `true`, `false`, or array |
| `MUC_CLEAR_MESSAGES_ON_LEAVE` | `true` | Clear cached messages when leaving a room |
| `MUC_RESPECT_AUTOJOIN` | `true` | Respect autojoin attribute on bookmarks |
| `MUC_SEND_PROBES` | `false` | Send presence probes for unknown authors |
| `MUC_SUBSCRIBE_TO_RAI` | `false` | XEP-0437 Room Activity Indicators |
| `MUC_MENTION_AUTOCOMPLETE_MIN_CHARS` | `0` | Min chars before mention autocomplete shows |
| `MUC_MENTION_AUTOCOMPLETE_FILTER` | `contains` | `contains` or `starts_with` |
| `MUC_MENTION_AUTOCOMPLETE_SHOW_AVATAR` | `true` | Show avatars in mention autocomplete |
| `MUC_SEARCH_SERVICE` | — | JID of MUC search service |
| `LOCKED_MUC_DOMAIN` | `false` | Restrict to `MUC_DOMAIN`. `mixed`: `true`, `false`, `'hidden'` |
| `LOCKED_MUC_NICKNAME` | `false` | Prevent users from changing their MUC nickname |
| `HIDE_MUC_PARTICIPANTS` | `false` | Hide participant list by default |
| `ENABLE_MUC_PUSH` | `false` | XEP-0357 push notifications for MUCs |
| `MUC_ROOMID_POLICY_HINT` | — | HTML text shown as a hint for room ID naming policy |
| `ROOMCONFIG_WHITELIST` | — | Comma-separated room config field names to show in room config form (empty = show all) |
| `MUC_SHOW_INFO_MESSAGES` | — | Comma-separated list of info message types to show in MUC (empty = all) |
| `MODTOOLS_DISABLE_ASSIGN` | `false` | `mixed-array`: disable affiliation/role assignment — `true`, `false`, or comma-separated roles |
| `MODTOOLS_DISABLE_QUERY` | — | Comma-separated affiliations/roles to disable in the moderator query tab |

### Nickname

| Variable | Default | Description |
|---|---|---|
| `DEFAULT_NICKNAME` | — | Static nickname |
| `NICKNAME_PREFIX` | — | If set, generates a unique per-browser nickname via localStorage (`<prefix>_<uuid8>`) |

### Messages / Archiving

| Variable | Default | Description |
|---|---|---|
| `MESSAGE_ARCHIVING` | — | MAM preference: `always`, `never`, or `roster` |
| `MESSAGE_ARCHIVING_TIMEOUT` | `20000` | Milliseconds to wait for archived messages |
| `ARCHIVED_MESSAGES_PAGE_SIZE` | `50` | Max archived messages per MAM query |
| `MAM_REQUEST_ALL_PAGES` | `false` | Request all MAM pages instead of just the latest |
| `AUTO_FILL_HISTORY_GAPS` | `true` | Automatically fill gaps in chat history |
| `MESSAGE_LIMIT` | `0` | Max characters per message (0 = unlimited) |
| `PRUNE_MESSAGES_ABOVE` | — | Keep history to this many messages |
| `PRUNING_BEHAVIOR` | `unscrolled` | When to prune: `unscrolled` or `scrolled` |
| `ALLOW_MESSAGE_CORRECTIONS` | `all` | `mixed`: `'all'`, `'last'`, or `false` |
| `ALLOW_MESSAGE_RETRACTION` | `all` | `mixed`: `'all'`, `'own'`, `'moderator'`, or `false` |
| `ALLOW_MESSAGE_STYLING` | `true` | XEP-0393 Message Styling |
| `SEND_CHAT_MARKERS` | `received,displayed,acknowledged` | Comma-separated XEP-0333 chat marker types to send |
| `SEND_CHAT_STATE_NOTIFICATIONS` | `true` | Send XEP-0085 chat state notifications |
| `SHOW_RETRACTION_WARNING` | `true` | Warn before retracting messages |
| `FILTER_BY_RESOURCE` | `false` | Ignore messages for a different resource |

### Security / Encryption

| Variable | Default | Description |
|---|---|---|
| `OMEMO_DEFAULT` | `false` | Enable OMEMO encryption by default |
| `ALLOW_USER_TRUST_OVERRIDE` | `true` | `mixed`: `true`, `false`, or `'off'` |

### UI

| Variable | Default | Description |
|---|---|---|
| `THEME` | `default` | `default`, `cyberpunk`, `dracula`, or `nord` |
| `DARK_THEME` | `dracula` | Theme used in dark mode |
| `COLORIZE_USERNAME` | `false` | Colorize nicknames per XEP-0392 |
| `TIME_FORMAT` | `HH:mm` | DayJS format string for timestamps |
| `SHOW_MESSAGE_AVATAR` | `true` | Show author avatars with messages |
| `SHOW_SEND_BUTTON` | `true` | Show send button in chat input |
| `SHOW_BACKGROUND` | `true` | Show background with converse.js logo |
| `SHOW_CLIENT_INFO` | `true` | Show About info icon in controlbox |
| `SHOW_CONTROLBOX_BY_DEFAULT` | `false` | Show contacts panel on load |
| `STICKY_CONTROLBOX` | `false` | Prevent the controlbox from being closed |
| `SHOW_IMAGES_INLINE` | `true` | Render images inline in chats |
| `RENDER_MEDIA` | `true` | `mixed`: `true`, `false`, or domain allowlist |
| `EMBED_3RD_PARTY_MEDIA_PLAYERS` | `true` | Embed YouTube, Spotify etc. |
| `USE_SYSTEM_EMOJIS` | `true` | Use OS emojis instead of Twemoji |
| `EMOJI_IMAGE_PATH` | — | Custom URL for Twemoji images |
| `POPULAR_EMOJIS` | — | Comma-separated emoji shortnames for the "popular" row |
| `EMOJI_CATEGORIES_LABEL` | — | Label shown above emoji category tabs |
| `ALLOWED_AUDIO_DOMAINS` | — | Comma-separated domains allowed to inline audio (empty = all) |
| `ALLOWED_IMAGE_DOMAINS` | — | Comma-separated domains allowed to inline images (empty = all) |
| `ALLOWED_VIDEO_DOMAINS` | — | Comma-separated domains allowed to inline video (empty = all) |
| `ALLOW_DRAGRESIZE` | `true` | Allow resizing chat panels |
| `DRAGRESIZE_TOP_MARGIN` | `0` | Minimum distance (px) from the top when dragging panels (overlayed mode only) |
| `ALLOW_URL_HISTORY_CHANGE` | `true` | Allow converse.js to update browser URL |
| `AUTO_FOCUS` | `true` | Auto-focus message input |
| `FETCH_URL_HEADERS` | `false` | Fetch URL headers to detect embeddable media |
| `ALLOW_ADHOC_COMMANDS` | `true` | XEP-0050 Ad-Hoc commands |
| `ALLOW_BOOKMARKS` | `true` | Enable room bookmarks |
| `ALLOW_PUBLIC_BOOKMARKS` | `false` | Allow public bookmarks |
| `ALLOW_MUC_INVITATIONS` | `true` | Allow room invitations |
| `SINGLETON` | `false` | Allow only one open chat at a time |
| `ALLOW_LOGOUT` | `true` | Show the logout button |
| `XHR_USER_SEARCH_URL` | — | URL for server-side user search |
| `GEOURI_REPLACEMENT` | — | URL template replacing `geo:` URIs (use `{lat}` and `{lon}` placeholders) |
| `GEOURI_REGEX` | — | JS regex literal to detect geo URIs (e.g. `/geo:[0-9.-]+,[0-9.-]+/`) |

### Notifications

| Variable | Default | Description |
|---|---|---|
| `NOTIFY_ALL_ROOM_MESSAGES` | `false` | Notify on all room messages, not just mentions |
| `NOTIFY_NICKNAMES_WITHOUT_REFERENCES` | `false` | Notify on nickname mentions without XEP-0372 references |
| `PLAY_SOUNDS` | `false` | Play sound on new message |
| `SOUNDS_PATH` | — | Custom URL for notification sounds |
| `SHOW_DESKTOP_NOTIFICATIONS` | `true` | `mixed`: `true`, `false`, or `'all'` |
| `SHOW_TAB_NOTIFICATIONS` | `true` | Show unread count in browser tab |
| `SHOW_CHAT_STATE_NOTIFICATIONS` | `false` | Desktop notifications for chat state changes |
| `NOTIFICATION_DELAY` | `5000` | Milliseconds to display desktop notifications |
| `NOTIFICATION_ICON` | — | Custom icon URL for desktop notifications |

### Plugins

| Variable | Default | Description |
|---|---|---|
| `BLACKLISTED_PLUGINS` | — | Comma-separated plugin names to disable |
| `WHITELISTED_PLUGINS` | — | Comma-separated plugin names to keep enabled |
| `RTL_LANGS` | `ar,fa,he,ug` | Comma-separated language codes treated as right-to-left |

### Advanced

#### `CONVERSE_EXTRA_CONFIG`

Escape hatch for options that require complex types (objects, arrays of objects) not expressible as a single string. Set to a raw JS snippet that will be injected verbatim into `converse.initialize({...})`.

Unsupported via dedicated vars: `connection_options`, `emoji_categories`, `visible_toolbar_buttons`, `push_app_servers`, `oauth_providers`, `muc_hats`.

```yaml
- CONVERSE_EXTRA_CONFIG=connection_options: {ws_opts: {timeout: 60000}}, visible_toolbar_buttons: {emoji: false},
```

#### `CUSTOM_HTML`

Mount your own `index.html` and point `CUSTOM_HTML` to its path inside the container. The nginx config and well-known files are still generated normally — only the HTML generation is skipped.

```yaml
volumes:
  - ./my-index.html:/custom/index.html:ro
environment:
  - CUSTOM_HTML=/custom/index.html
```

### XMPP auto-discovery (well-known)

When `BOSH_SERVICE_URL` or `WEBSOCKET_URL` is set, the container automatically generates and serves:

- `/.well-known/host-meta` — XRD XML (`application/xrd+xml`)
- `/.well-known/host-meta.json` — JRD JSON (`application/jrd+json`)

No volume mount or extra configuration needed. Only the links for set URLs are included.

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
podman build --network host --build-arg CONVERSEJS_VERSION=12.0.0 -t conversejs .
```

The ConverseJS release archive is downloaded from GitHub at build time. The version is controlled by the `CONVERSEJS_VERSION` build arg — see [converse.js releases](https://github.com/conversejs/converse.js/releases) for available versions.

## CI

Two GitHub Actions workflows are provided:

| Workflow | Trigger | Action |
|---|---|---|
| `deploy.yaml` | Push to `main`/`dev`, weekly schedule, manual | Build multi-arch image (`amd64`, `arm64`, `armv7`) and push to GHCR + Docker Hub |
| `build_test.yaml` | Push to feature branches, PRs to `main`/`dev` | Build only, no push |

Required repository secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`.
