FROM node:22-alpine AS build
WORKDIR /workspace
RUN corepack enable && corepack prepare pnpm@9.15.0 --activate
COPY package.json pnpm-workspace.yaml tsconfig.base.json ./
COPY apps ./apps
COPY packages ./packages
COPY services ./services
COPY infrastructure ./infrastructure
RUN pnpm install --no-frozen-lockfile
RUN pnpm --filter @internlink/database db:generate
RUN pnpm --filter @internlink/api build

FROM node:22-alpine AS runtime
WORKDIR /workspace
ENV NODE_ENV=production
RUN corepack enable && corepack prepare pnpm@9.15.0 --activate
COPY --from=build /workspace /workspace
EXPOSE 3001
CMD ["pnpm", "--dir", "apps/api", "start:prod"]
