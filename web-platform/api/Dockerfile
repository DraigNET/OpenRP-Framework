# syntax=docker/dockerfile:1
# Build context = repository root. In EasyPanel set the Dockerfile path to "api/Dockerfile".

FROM node:22-slim AS builder
WORKDIR /app
COPY api/package.json api/package-lock.json ./
RUN npm ci
COPY api/ ./
RUN npm run build

FROM node:22-slim AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3001
COPY api/package.json api/package-lock.json ./
RUN npm ci --omit=dev
COPY --from=builder /app/dist ./dist
EXPOSE 3001
CMD ["node", "dist/index.js"]
