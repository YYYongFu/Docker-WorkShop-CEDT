# syntax=docker/dockerfile:1.7
FROM node:20.11-slim AS builder
WORKDIR /app
COPY app/package.json app/package-lock.json ./
RUN npm ci --omit=dev
COPY app/ ./
# Patch the vulnerable transitive dependency without editing the supplied app files.
RUN npm install --omit=dev --no-save --package-lock=false proxy-addr@2.0.8

FROM node:20.11-slim
# Apply Debian security fixes; npm and Yarn are not needed to run this app.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libgnutls30 perl-base \
    && rm -rf /var/lib/apt/lists/* /usr/local/lib/node_modules/npm /opt/yarn-* \
    && rm -f /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/yarn /usr/local/bin/yarnpkg
WORKDIR /app
COPY --from=builder /app /app
ENV NODE_ENV=production
EXPOSE 3000
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
  CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode===200?0:1)).on('error', () => process.exit(1))"
CMD ["node", "src/index.js"]
