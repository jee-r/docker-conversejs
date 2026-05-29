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

# Container-specific vars (not converse.js options)
ENV APP_TITLE="ConverseJS" \
    NICKNAME_PREFIX="" \
    CONVERSE_EXTRA_CONFIG="" \
    CUSTOM_HTML=""

# Opinionated converse.js defaults
ENV CONVERSEJS_VIEW_MODE="fullscreen"

COPY --from=builder /build /usr/share/nginx/html/package
COPY entrypoint.sh /entrypoint.sh

USER root
RUN chmod +x /entrypoint.sh \
    && chown -R nginx:nginx /usr/share/nginx/html \
    && chown -R nginx:nginx /etc/nginx/conf.d
USER nginx

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget -q --spider http://127.0.0.1:8080/ || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
