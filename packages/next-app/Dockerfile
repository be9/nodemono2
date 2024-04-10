FROM node:20-alpine AS base

ARG MONOREPO_PACKAGE=@nodemono2/next-app
ARG TURBO_VERSION=1.13.0

FROM base AS buildbase

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

RUN apk add --no-cache \
      bash \
      build-base \
      python3

###################################

FROM buildbase AS builder

WORKDIR /app
RUN pnpm add -g turbo@$TURBO_VERSION
COPY . .
RUN turbo prune $MONOREPO_PACKAGE --docker

###################################

# Add lockfile and package.json's of isolated subworkspace
FROM buildbase AS installer
WORKDIR /app

# First install the dependencies (as they change less often)
COPY .gitignore .gitignore
COPY --from=builder /app/out/json/ .
COPY --from=builder /app/out/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=builder /app/out/pnpm-workspace.yaml ./pnpm-workspace.yaml
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile

###################################

FROM installer AS turbo_builder

COPY --from=bufbuild/buf:1.30.0 /usr/local/bin/buf /usr/local/bin/

# Build the project
COPY --from=builder /app/out/full/ .
COPY tsconfig.json ./tsconfig.json

# Replace symlink with a directory
RUN rm -f ./packages/proto/protosrc
COPY proto/src ./packages/proto/protosrc

RUN pnpm turbo run codegen --filter=$MONOREPO_PACKAGE...
RUN pnpm turbo run build:self --filter=$MONOREPO_PACKAGE...

###################################

FROM base AS runner
WORKDIR /app

RUN apk add --no-cache bash

ENV NODE_ENV=production

COPY --from=turbo_builder /app/packages/next-app/.next/standalone ./
COPY --from=turbo_builder /app/packages/next-app/public /app/packages/next-app/public
COPY --from=turbo_builder /app/packages/next-app/.next/static /app/packages/next-app/.next/static

CMD HOSTNAME=localhost cd packages/next-app && node server.js

EXPOSE 3000
