# syntax=docker/dockerfile:1.7
ARG GO_VERSION=1.24.1

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS build

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ARG VERSION=dev
ARG VCS_REF=unknown
ARG BUILD_DATE

WORKDIR /src

RUN apk add --no-cache ca-certificates

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go mod download

COPY . .

ENV CGO_ENABLED=0
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    sh -c 'GOARM=""; if [ "$TARGETARCH" = "arm" ] && [ -n "$TARGETVARIANT" ]; then GOARM="${TARGETVARIANT#v}"; fi; \
      GOOS=$TARGETOS GOARCH=$TARGETARCH GOARM=$GOARM \
      go build -trimpath -ldflags "-s -w" -o /out/gha-fix ./cmd/gha-fix'

FROM --platform=$TARGETPLATFORM alpine:3.20 AS runtime

ARG VERSION=dev
ARG VCS_REF=unknown
ARG BUILD_DATE

LABEL org.opencontainers.image.title="gha-fix" \
      org.opencontainers.image.description="Fix GitHub Actions workflow files" \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.created=$BUILD_DATE

RUN apk add --no-cache ca-certificates

COPY --from=build /out/gha-fix /usr/local/bin/gha-fix

ENTRYPOINT ["gha-fix"]
