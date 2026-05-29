# Stage 1: Download and prepare ConverseJS
FROM alpine:latest AS builder
# renovate: datasource=github-releases depName=conversejs/converse.js
ARG CONVERSEJS_VERSION=13.0.1
WORKDIR /build
RUN apk add --no-cache wget tar \
    && wget --no-verbose https://github.com/conversejs/converse.js/releases/download/v${CONVERSEJS_VERSION}/converse.js-${CONVERSEJS_VERSION}.tgz \
    && tar -xzf converse.js-${CONVERSEJS_VERSION}.tgz --strip-components=1 \
    && rm converse.js-${CONVERSEJS_VERSION}.tgz

# Stage 2: Final nginx image
FROM ghcr.io/nginx/nginx-unprivileged:alpine

LABEL name="docker-conversejs" \
      maintainer="Jee jee@jeer.fr" \
      description="Web-based XMPP/Jabber chat client" \
      url="https://conversejs.org/" \
      org.label-schema.vcs-url="https://github.com/jee-r/docker-conversejs" \
      org.opencontainers.image.source="https://github.com/jee-r/docker-conversejs"

ENV APP_TITLE="ConverseJS" \
    VIEW_MODE="fullscreen" \
    # Connection
    BOSH_SERVICE_URL="" \
    WEBSOCKET_URL="" \
    JID="" \
    PRIORITY="" \
    PING_INTERVAL="" \
    STANZA_TIMEOUT="" \
    ENABLE_SMACKS="" \
    SMACKS_MAX_UNACKED_STANZAS="" \
    DISCOVER_CONNECTION_METHODS="" \
    CREDENTIALS_URL="" \
    PREBIND_URL="" \
    CSI_WAITING_TIME="" \
    REUSE_SCRAM_KEYS="" \
    # Authentication
    AUTHENTICATION="" \
    AUTO_LOGIN="" \
    AUTO_RECONNECT="" \
    AUTO_SUBSCRIBE="" \
    REGISTRATION_DOMAIN="" \
    ALLOW_REGISTRATION="" \
    DEFAULT_DOMAIN="" \
    LOCKED_DOMAIN="" \
    DOMAIN_PLACEHOLDER="" \
    SHOW_CONNECTION_URL_INPUT="" \
    XMPP_PROVIDERS_URL="" \
    PROVIDERS_LINK="" \
    AUTOCOMPLETE_PROVIDERS_URL="" \
    # Session / Storage
    KEEPALIVE="" \
    CLEAR_CACHE_ON_LOGOUT="" \
    CLEAR_MESSAGES_ON_RECONNECTION="" \
    PERSISTENT_STORE="" \
    IDLE_PRESENCE_TIMEOUT="" \
    AUTO_AWAY="" \
    AUTO_XA="" \
    SYNCHRONIZE_AVAILABILITY="" \
    # Presence / Roster
    ALLOW_CONTACT_REQUESTS="" \
    ALLOW_CONTACT_REMOVAL="" \
    ALLOW_NON_ROSTER_MESSAGING="" \
    ROSTER_GROUPS="" \
    SHOW_SELF_IN_ROSTER="" \
    ENABLE_ROSTER_VERSIONING="" \
    # Rooms (MUC)
    MUC_DOMAIN="" \
    MUC_GROUPED_BY_DOMAIN="" \
    MUC_HISTORY_MAX_STANZAS="" \
    MUC_INSTANT_ROOMS="" \
    MUC_NICKNAME_FROM_JID="" \
    AUTO_REGISTER_MUC_NICKNAME="" \
    MUC_SHOW_LOGS_BEFORE_JOIN="" \
    MUC_FETCH_MEMBERS="" \
    MUC_CLEAR_MESSAGES_ON_LEAVE="" \
    MUC_RESPECT_AUTOJOIN="" \
    MUC_SEND_PROBES="" \
    MUC_SUBSCRIBE_TO_RAI="" \
    MUC_MENTION_AUTOCOMPLETE_MIN_CHARS="" \
    MUC_MENTION_AUTOCOMPLETE_FILTER="" \
    MUC_MENTION_AUTOCOMPLETE_SHOW_AVATAR="" \
    MUC_SEARCH_SERVICE="" \
    LOCKED_MUC_DOMAIN="" \
    LOCKED_MUC_NICKNAME="" \
    HIDE_MUC_PARTICIPANTS="" \
    ENABLE_MUC_PUSH="" \
    AUTO_JOIN_ON_INVITE="" \
    AUTO_LIST_ROOMS="" \
    AUTO_JOIN_ROOMS="" \
    AUTO_JOIN_PRIVATE_CHATS="" \
    ROOMCONFIG_WHITELIST="" \
    MUC_SHOW_INFO_MESSAGES="" \
    MODTOOLS_DISABLE_ASSIGN="" \
    MODTOOLS_DISABLE_QUERY="" \
    # Nickname
    DEFAULT_NICKNAME="" \
    NICKNAME_PREFIX="" \
    # Messages / Archiving
    MESSAGE_ARCHIVING="" \
    MESSAGE_ARCHIVING_TIMEOUT="" \
    ARCHIVED_MESSAGES_PAGE_SIZE="" \
    MAM_REQUEST_ALL_PAGES="" \
    AUTO_FILL_HISTORY_GAPS="" \
    MESSAGE_LIMIT="" \
    PRUNE_MESSAGES_ABOVE="" \
    PRUNING_BEHAVIOR="" \
    ALLOW_MESSAGE_CORRECTIONS="" \
    ALLOW_MESSAGE_RETRACTION="" \
    ALLOW_MESSAGE_STYLING="" \
    SEND_CHAT_MARKERS="" \
    SEND_CHAT_STATE_NOTIFICATIONS="" \
    SHOW_RETRACTION_WARNING="" \
    FILTER_BY_RESOURCE="" \
    # Security / Encryption
    OMEMO_DEFAULT="" \
    ALLOW_USER_TRUST_OVERRIDE="" \
    # UI
    THEME="" \
    DARK_THEME="" \
    COLORIZE_USERNAME="" \
    TIME_FORMAT="" \
    SHOW_MESSAGE_AVATAR="" \
    SHOW_SEND_BUTTON="" \
    SHOW_BACKGROUND="" \
    SHOW_CLIENT_INFO="" \
    SHOW_CONTROLBOX_BY_DEFAULT="" \
    STICKY_CONTROLBOX="" \
    SHOW_IMAGES_INLINE="" \
    RENDER_MEDIA="" \
    EMBED_3RD_PARTY_MEDIA_PLAYERS="" \
    USE_SYSTEM_EMOJIS="" \
    EMOJI_IMAGE_PATH="" \
    POPULAR_EMOJIS="" \
    EMOJI_CATEGORIES_LABEL="" \
    ALLOWED_AUDIO_DOMAINS="" \
    ALLOWED_IMAGE_DOMAINS="" \
    ALLOWED_VIDEO_DOMAINS="" \
    ALLOW_DRAGRESIZE="" \
    DRAGRESIZE_TOP_MARGIN="" \
    ALLOW_URL_HISTORY_CHANGE="" \
    AUTO_FOCUS="" \
    FETCH_URL_HEADERS="" \
    ALLOW_ADHOC_COMMANDS="" \
    ALLOW_BOOKMARKS="" \
    ALLOW_PUBLIC_BOOKMARKS="" \
    ALLOW_MUC_INVITATIONS="" \
    SINGLETON="" \
    ALLOW_LOGOUT="" \
    LOGLEVEL="" \
    I18N="" \
    LOCALES="" \
    # Notifications
    NOTIFY_ALL_ROOM_MESSAGES="" \
    NOTIFY_NICKNAMES_WITHOUT_REFERENCES="" \
    PLAY_SOUNDS="" \
    SOUNDS_PATH="" \
    SHOW_DESKTOP_NOTIFICATIONS="" \
    SHOW_TAB_NOTIFICATIONS="" \
    SHOW_CHAT_STATE_NOTIFICATIONS="" \
    NOTIFICATION_DELAY="" \
    NOTIFICATION_ICON="" \
    # Roster display
    HIDE_OFFLINE_USERS="" \
    LAZY_LOAD_VCARDS="" \
    # Misc
    STRICT_PLUGIN_DEPENDENCIES="" \
    XHR_USER_SEARCH_URL="" \
    GEOURI_REPLACEMENT="" \
    GEOURI_REGEX="" \
    MUC_ROOMID_POLICY_HINT="" \
    BLACKLISTED_PLUGINS="" \
    WHITELISTED_PLUGINS="" \
    RTL_LANGS="" \
    CONVERSE_EXTRA_CONFIG="" \
    CUSTOM_HTML=""

COPY --from=builder /build /usr/share/nginx/html/package
COPY entrypoint.sh /entrypoint.sh

USER root
RUN chmod +x /entrypoint.sh \
    && chown -R nginx:nginx /usr/share/nginx/html \
    && chown -R nginx:nginx /etc/nginx/conf.d
USER nginx

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget -qO- http://localhost:8080/ > /dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
