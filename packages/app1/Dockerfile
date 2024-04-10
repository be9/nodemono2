FROM node:20-alpine AS base

ARG MONOREPO_PACKAGE=@nodemono2/app1
ARG TURBO_VERSION=1.13.0

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
  PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

FROM base AS buildbase

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

RUN apk add --no-cache \
      bash \
      build-base \
      python3

COPY --from=bufbuild/buf:1.30.0 /usr/local/bin/buf /usr/local/bin/

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

# Build the project
COPY --from=builder /app/out/full/ .
COPY tsconfig.json ./tsconfig.json

# Replace symlink with a directory
RUN rm -f ./packages/proto/protosrc
COPY proto/src ./packages/proto/protosrc

RUN pnpm turbo run codegen --filter=$MONOREPO_PACKAGE...
RUN pnpm turbo run build:self --filter=$MONOREPO_PACKAGE...

###################################

FROM buildbase AS prod_installer

WORKDIR /app

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
  PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# First install the dependencies (as they change less often)
COPY .gitignore .gitignore
COPY --from=builder /app/out/json/ .
COPY --from=builder /app/out/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=builder /app/out/pnpm-workspace.yaml ./pnpm-workspace.yaml
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

###################################

FROM base AS runner
WORKDIR /app

RUN apk add --no-cache \
      bash \
      chromium nss freetype harfbuzz ca-certificates ttf-freefont

COPY --from=prod_installer /app/package.json ./package.json
COPY --from=prod_installer /app/node_modules ./node_modules
COPY --from=turbo_builder /app/packages ./packages

EXPOSE 3000

ENTRYPOINT ["node", "packages/app1/build/index.js"]
