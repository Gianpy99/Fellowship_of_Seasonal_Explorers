# syntax=docker/dockerfile:1
# Multi-stage build for the Family Portal (ARM64 Raspberry Pi and x86 both work).
#   docker build --target test .   -> type-check + server tests (used by Jenkins)
#   docker build .                 -> small runtime image

FROM node:22-alpine AS base
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .

FROM base AS test
RUN npm run typecheck && npm test

FROM base AS build
RUN npm run build && npm prune --omit=dev --no-audit --no-fund

FROM node:22-alpine AS runtime
ENV NODE_ENV=production \
    APP_ENV=production \
    PORT=8080 \
    DATA_DIR=/app/data
WORKDIR /app
COPY --from=build /app/package.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/server ./server
COPY --from=build /app/content ./content
COPY --from=build /app/dist ./dist
# The named volume is mounted here; creating it as "node" makes a fresh volume writable.
RUN rm -rf server/test && mkdir -p /app/data && chown node:node /app/data
USER node
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD node -e "fetch('http://localhost:'+(process.env.PORT||8080)+'/health').then(r=>process.exit(r.ok?0:1),()=>process.exit(1))"
CMD ["node", "server/index.js"]
