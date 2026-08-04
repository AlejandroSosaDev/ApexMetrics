# syntax=docker/dockerfile:1

# ---- build ------------------------------------------------------------
FROM node:22-alpine AS build
WORKDIR /app

RUN corepack enable

# Dependencies first so this layer only invalidates when the lockfile
# changes, not on every source edit.
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY . .

# Vite inlines VITE_ variables into the bundle at build time, not at
# container start — there is no runtime env step for a static SPA, so the
# API's address must be known here.
ARG VITE_API_BASE_URL
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
RUN pnpm build

# ---- runtime ------------------------------------------------------------
# nginx-unprivileged, not the official nginx image: the official image needs
# root to bind port 80. This one listens on 8080 by design, so the container
# runs as a non-root user with no capability drop or manual chown required.
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime

COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

# 127.0.0.1, not localhost: this image's /etc/hosts resolves "localhost" to
# ::1 first, but nginx only binds the IPv4 wildcard, so wget against
# "localhost" gets "connection refused" even when the server is healthy.
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
    CMD wget --spider -q http://127.0.0.1:8080/ || exit 1
