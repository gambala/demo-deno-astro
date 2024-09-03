FROM denoland/deno:alpine-1.46.2 AS base

WORKDIR /app

FROM base AS builder

RUN apk add --no-cache curl bash
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:$PATH"

COPY package.json bun.lockb ./

FROM builder AS prod-deps
RUN bun install --frozen-lockfile

FROM builder AS build-deps
RUN bun install --frozen-lockfile

FROM build-deps AS build
COPY . .
RUN bun run build

FROM base AS runtime
COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist

# Install curl for Kamal health checks and bash for shell access
RUN apk add --no-cache curl bash

RUN deno cache ./dist/server/entry.mjs

USER deno
EXPOSE 8085

CMD ["deno", "run", "--allow-net", "--allow-read", "--allow-env", "./dist/server/entry.mjs"]
