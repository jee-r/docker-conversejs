#!/bin/sh
set -e

HTML_OUTPUT=/usr/share/nginx/html/index.html
NGINX_CONF=/etc/nginx/conf.d/default.conf
WELL_KNOWN_DIR=/usr/share/nginx/html/.well-known

# Append a quoted string option to CFG if the value is non-empty
opt_str() { [ -n "$2" ] && CFG="${CFG}
    ${1}: \"${2}\"," || true; }

# Append a literal (bool/number) option to CFG if the value is non-empty
opt_val() { [ -n "$2" ] && CFG="${CFG}
    ${1}: ${2}," || true; }

# Append an option that can be bool/number OR a string (auto-quotes strings)
opt_mixed() {
    [ -z "$2" ] && return 0
    case "$2" in
        true|false|[0-9]*) CFG="${CFG}
    ${1}: ${2}," ;;
        *) CFG="${CFG}
    ${1}: \"${2}\"," ;;
    esac
}

# Append a comma-separated value as a JS array of quoted strings
opt_arr() {
    [ -z "$2" ] && return 0
    arr_js=""
    IFS=','
    for item in $2; do
        item="${item# }"; item="${item% }"
        [ -n "$arr_js" ] && arr_js="${arr_js},"
        arr_js="${arr_js}\"${item}\""
    done
    unset IFS
    CFG="${CFG}
    ${1}: [${arr_js}],"
}

# Append a raw JS regex literal (value passed as-is, e.g. /pattern/flags)
opt_regex() { [ -n "$2" ] && CFG="${CFG}
    ${1}: ${2}," || true; }

# Append an option that is either a boolean OR a comma-separated JS array of strings
opt_mixed_arr() {
    [ -z "$2" ] && return 0
    case "$2" in
        true|false) CFG="${CFG}
    ${1}: ${2}," ;;
        *)
            arr_js=""
            IFS=','
            for item in $2; do
                item="${item# }"; item="${item% }"
                [ -n "$arr_js" ] && arr_js="${arr_js},"
                arr_js="${arr_js}\"${item}\""
            done
            unset IFS
            CFG="${CFG}
    ${1}: [${arr_js}],"
        ;;
    esac
}

# ── nginx ──────────────────────────────────────────────────────────────────

WELL_KNOWN_BLOCK=""
if [ -n "$BOSH_SERVICE_URL" ] || [ -n "$WEBSOCKET_URL" ]; then
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

if [ -n "$BOSH_SERVICE_URL" ] || [ -n "$WEBSOCKET_URL" ]; then
    mkdir -p "$WELL_KNOWN_DIR"

    XML_LINKS=""
    [ -n "$BOSH_SERVICE_URL" ] && XML_LINKS="${XML_LINKS}
    <link rel=\"urn:xmpp:alt-connections:xbosh\" href=\"${BOSH_SERVICE_URL}\" />"
    [ -n "$WEBSOCKET_URL" ]    && XML_LINKS="${XML_LINKS}
    <link rel=\"urn:xmpp:alt-connections:websocket\" href=\"${WEBSOCKET_URL}\" />"

    cat > "${WELL_KNOWN_DIR}/host-meta" << XML
<?xml version="1.0" encoding="utf-8"?>
<XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0">
${XML_LINKS}
</XRD>
XML

    JSON_LINKS=""
    [ -n "$BOSH_SERVICE_URL" ] && \
        JSON_LINKS="        {\"rel\": \"urn:xmpp:alt-connections:xbosh\", \"href\": \"${BOSH_SERVICE_URL}\"}"
    if [ -n "$WEBSOCKET_URL" ]; then
        [ -n "$JSON_LINKS" ] && JSON_LINKS="${JSON_LINKS},"
        JSON_LINKS="${JSON_LINKS}
        {\"rel\": \"urn:xmpp:alt-connections:websocket\", \"href\": \"${WEBSOCKET_URL}\"}"
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

CFG="    view_mode: \"${VIEW_MODE:-fullscreen}\","
CFG="${CFG}
    assets_path: \"/package/dist/\","

# Connection
opt_str  bosh_service_url                   "$BOSH_SERVICE_URL"
opt_str  websocket_url                      "$WEBSOCKET_URL"
opt_str  jid                                "$JID"
opt_val  priority                           "$PRIORITY"
opt_val  ping_interval                      "$PING_INTERVAL"
opt_val  stanza_timeout                     "$STANZA_TIMEOUT"
opt_val  enable_smacks                      "$ENABLE_SMACKS"
opt_val  smacks_max_unacked_stanzas         "$SMACKS_MAX_UNACKED_STANZAS"
opt_val  discover_connection_methods        "$DISCOVER_CONNECTION_METHODS"
opt_str  credentials_url                    "$CREDENTIALS_URL"
opt_str  prebind_url                        "$PREBIND_URL"
opt_val  csi_waiting_time                   "$CSI_WAITING_TIME"
opt_val  reuse_scram_keys                   "$REUSE_SCRAM_KEYS"

# Authentication
opt_str  authentication                     "$AUTHENTICATION"
opt_val  auto_login                         "$AUTO_LOGIN"
opt_val  auto_reconnect                     "$AUTO_RECONNECT"
opt_val  auto_subscribe                     "$AUTO_SUBSCRIBE"
opt_str  registration_domain               "$REGISTRATION_DOMAIN"
opt_val  allow_registration                 "$ALLOW_REGISTRATION"
opt_str  default_domain                     "$DEFAULT_DOMAIN"
opt_str  locked_domain                      "$LOCKED_DOMAIN"
opt_str  domain_placeholder                 "$DOMAIN_PLACEHOLDER"
opt_val  show_connection_url_input          "$SHOW_CONNECTION_URL_INPUT"
opt_str  xmpp_providers_url                "$XMPP_PROVIDERS_URL"
opt_str  providers_link                     "$PROVIDERS_LINK"
opt_str  autocomplete_providers_url         "$AUTOCOMPLETE_PROVIDERS_URL"

# Session / Storage
opt_val  keepalive                          "$KEEPALIVE"
opt_val  clear_cache_on_logout              "$CLEAR_CACHE_ON_LOGOUT"
opt_val  clear_messages_on_reconnection     "$CLEAR_MESSAGES_ON_RECONNECTION"
opt_str  persistent_store                   "$PERSISTENT_STORE"
opt_val  idle_presence_timeout              "$IDLE_PRESENCE_TIMEOUT"
opt_val  auto_away                          "$AUTO_AWAY"
opt_val  auto_xa                            "$AUTO_XA"
opt_mixed synchronize_availability          "$SYNCHRONIZE_AVAILABILITY"

# Presence / Roster
opt_val  allow_contact_requests             "$ALLOW_CONTACT_REQUESTS"
opt_val  allow_contact_removal              "$ALLOW_CONTACT_REMOVAL"
opt_val  allow_non_roster_messaging         "$ALLOW_NON_ROSTER_MESSAGING"
opt_val  roster_groups                      "$ROSTER_GROUPS"
opt_val  show_self_in_roster                "$SHOW_SELF_IN_ROSTER"
opt_val  enable_roster_versioning           "$ENABLE_ROSTER_VERSIONING"

# Rooms (MUC)
opt_str  muc_domain                         "$MUC_DOMAIN"
opt_val  muc_grouped_by_domain              "$MUC_GROUPED_BY_DOMAIN"
opt_val  muc_history_max_stanzas            "$MUC_HISTORY_MAX_STANZAS"
opt_val  muc_instant_rooms                  "$MUC_INSTANT_ROOMS"
opt_val  muc_nickname_from_jid              "$MUC_NICKNAME_FROM_JID"
opt_mixed auto_register_muc_nickname        "$AUTO_REGISTER_MUC_NICKNAME"
opt_val  muc_show_logs_before_join          "$MUC_SHOW_LOGS_BEFORE_JOIN"
opt_mixed muc_fetch_members                 "$MUC_FETCH_MEMBERS"
opt_val  muc_clear_messages_on_leave        "$MUC_CLEAR_MESSAGES_ON_LEAVE"
opt_val  muc_respect_autojoin               "$MUC_RESPECT_AUTOJOIN"
opt_val  muc_send_probes                    "$MUC_SEND_PROBES"
opt_val  muc_subscribe_to_rai               "$MUC_SUBSCRIBE_TO_RAI"
opt_val  muc_mention_autocomplete_min_chars "$MUC_MENTION_AUTOCOMPLETE_MIN_CHARS"
opt_str  muc_mention_autocomplete_filter    "$MUC_MENTION_AUTOCOMPLETE_FILTER"
opt_val  muc_mention_autocomplete_show_avatar "$MUC_MENTION_AUTOCOMPLETE_SHOW_AVATAR"
opt_str  muc_search_service                 "$MUC_SEARCH_SERVICE"
opt_mixed locked_muc_domain                 "$LOCKED_MUC_DOMAIN"
opt_val  locked_muc_nickname                "$LOCKED_MUC_NICKNAME"
opt_val  hide_muc_participants              "$HIDE_MUC_PARTICIPANTS"
opt_val  enable_muc_push                    "$ENABLE_MUC_PUSH"
opt_val  auto_join_on_invite                "$AUTO_JOIN_ON_INVITE"
opt_val  auto_list_rooms                    "$AUTO_LIST_ROOMS"
opt_arr  auto_join_rooms                    "$AUTO_JOIN_ROOMS"
opt_arr  auto_join_private_chats            "$AUTO_JOIN_PRIVATE_CHATS"
opt_arr  roomconfig_whitelist               "$ROOMCONFIG_WHITELIST"
opt_arr  muc_show_info_messages             "$MUC_SHOW_INFO_MESSAGES"
opt_mixed_arr modtools_disable_assign       "$MODTOOLS_DISABLE_ASSIGN"
opt_arr  modtools_disable_query             "$MODTOOLS_DISABLE_QUERY"

# Nickname
opt_str  nickname                           "$DEFAULT_NICKNAME"

# Messages / Archiving
opt_str  message_archiving                  "$MESSAGE_ARCHIVING"
opt_val  message_archiving_timeout          "$MESSAGE_ARCHIVING_TIMEOUT"
opt_val  archived_messages_page_size        "$ARCHIVED_MESSAGES_PAGE_SIZE"
opt_val  mam_request_all_pages              "$MAM_REQUEST_ALL_PAGES"
opt_val  auto_fill_history_gaps             "$AUTO_FILL_HISTORY_GAPS"
opt_val  message_limit                      "$MESSAGE_LIMIT"
opt_val  prune_messages_above               "$PRUNE_MESSAGES_ABOVE"
opt_str  pruning_behavior                   "$PRUNING_BEHAVIOR"
opt_mixed allow_message_corrections         "$ALLOW_MESSAGE_CORRECTIONS"
opt_mixed allow_message_retraction          "$ALLOW_MESSAGE_RETRACTION"
opt_val  allow_message_styling              "$ALLOW_MESSAGE_STYLING"
opt_arr  send_chat_markers                  "$SEND_CHAT_MARKERS"
opt_val  send_chat_state_notifications      "$SEND_CHAT_STATE_NOTIFICATIONS"
opt_val  show_retraction_warning            "$SHOW_RETRACTION_WARNING"
opt_val  filter_by_resource                 "$FILTER_BY_RESOURCE"

# Security / Encryption
opt_val  omemo_default                      "$OMEMO_DEFAULT"
opt_mixed allow_user_trust_override         "$ALLOW_USER_TRUST_OVERRIDE"

# UI
opt_str  theme                              "$THEME"
opt_str  dark_theme                         "$DARK_THEME"
opt_val  colorize_username                  "$COLORIZE_USERNAME"
opt_str  time_format                        "$TIME_FORMAT"
opt_val  show_message_avatar                "$SHOW_MESSAGE_AVATAR"
opt_val  show_send_button                   "$SHOW_SEND_BUTTON"
opt_val  show_background                    "$SHOW_BACKGROUND"
opt_val  show_client_info                   "$SHOW_CLIENT_INFO"
opt_val  show_controlbox_by_default         "$SHOW_CONTROLBOX_BY_DEFAULT"
opt_val  sticky_controlbox                  "$STICKY_CONTROLBOX"
opt_val  show_images_inline                 "$SHOW_IMAGES_INLINE"
opt_mixed_arr render_media                  "$RENDER_MEDIA"
opt_val  embed_3rd_party_media_players      "$EMBED_3RD_PARTY_MEDIA_PLAYERS"
opt_val  use_system_emojis                  "$USE_SYSTEM_EMOJIS"
opt_str  emoji_image_path                   "$EMOJI_IMAGE_PATH"
opt_arr  popular_emojis                     "$POPULAR_EMOJIS"
opt_str  emoji_categories_label             "$EMOJI_CATEGORIES_LABEL"
opt_arr  allowed_audio_domains              "$ALLOWED_AUDIO_DOMAINS"
opt_arr  allowed_image_domains              "$ALLOWED_IMAGE_DOMAINS"
opt_arr  allowed_video_domains              "$ALLOWED_VIDEO_DOMAINS"
opt_val  allow_dragresize                   "$ALLOW_DRAGRESIZE"
opt_val  dragresize_top_margin             "$DRAGRESIZE_TOP_MARGIN"
opt_val  allow_url_history_change           "$ALLOW_URL_HISTORY_CHANGE"
opt_val  auto_focus                         "$AUTO_FOCUS"
opt_val  fetch_url_headers                  "$FETCH_URL_HEADERS"
opt_val  allow_adhoc_commands               "$ALLOW_ADHOC_COMMANDS"
opt_val  allow_bookmarks                    "$ALLOW_BOOKMARKS"
opt_val  allow_public_bookmarks             "$ALLOW_PUBLIC_BOOKMARKS"
opt_val  allow_muc_invitations              "$ALLOW_MUC_INVITATIONS"
opt_val  singleton                          "$SINGLETON"
opt_val  allow_logout                       "$ALLOW_LOGOUT"
opt_str  loglevel                           "$LOGLEVEL"
opt_str  i18n                               "$I18N"
opt_arr  locales                            "$LOCALES"

# Notifications
opt_val  notify_all_room_messages           "$NOTIFY_ALL_ROOM_MESSAGES"
opt_val  notify_nicknames_without_references "$NOTIFY_NICKNAMES_WITHOUT_REFERENCES"
opt_val  play_sounds                        "$PLAY_SOUNDS"
opt_str  sounds_path                        "$SOUNDS_PATH"
opt_mixed show_desktop_notifications        "$SHOW_DESKTOP_NOTIFICATIONS"
opt_val  show_tab_notifications             "$SHOW_TAB_NOTIFICATIONS"
opt_val  show_chat_state_notifications      "$SHOW_CHAT_STATE_NOTIFICATIONS"
opt_val  notification_delay                 "$NOTIFICATION_DELAY"
opt_str  notification_icon                  "$NOTIFICATION_ICON"

# Roster display
opt_val  hide_offline_users                 "$HIDE_OFFLINE_USERS"
opt_val  lazy_load_vcards                   "$LAZY_LOAD_VCARDS"

# Misc
opt_val  strict_plugin_dependencies         "$STRICT_PLUGIN_DEPENDENCIES"
opt_str  xhr_user_search_url                "$XHR_USER_SEARCH_URL"
opt_str  geouri_replacement                 "$GEOURI_REPLACEMENT"
opt_regex geouri_regex                      "$GEOURI_REGEX"
opt_str  muc_roomid_policy_hint             "$MUC_ROOMID_POLICY_HINT"
opt_arr  blacklisted_plugins                "$BLACKLISTED_PLUGINS"
opt_arr  whitelisted_plugins                "$WHITELISTED_PLUGINS"
opt_arr  rtl_langs                          "$RTL_LANGS"

# Raw JS config for complex options (objects, arrays of objects)
# e.g. CONVERSE_EXTRA_CONFIG=connection_options: {ws_opts: {timeout: 60000}},
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
