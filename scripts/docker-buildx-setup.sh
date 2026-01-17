#!/usr/bin/env bash
set -euo pipefail

# Create and activate a docker-container buildx builder for multi-arch builds.
# Usage: ./scripts/docker-buildx-setup.sh [builder-name]

BUILDER_NAME=${1:-cross-builder}

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required" >&2
  exit 1
fi

if ! docker buildx version >/dev/null 2>&1; then
  echo "docker buildx is required (Docker Desktop or docker-buildx plugin)" >&2
  exit 1
fi

if docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
  echo "Using existing builder: $BUILDER_NAME"
else
  echo "Creating builder: $BUILDER_NAME"
  docker buildx create --name "$BUILDER_NAME" --driver docker-container
fi

echo "Selecting builder: $BUILDER_NAME"
docker buildx use "$BUILDER_NAME"

echo "Bootstrapping buildkit for $BUILDER_NAME"
docker buildx inspect --bootstrap >/dev/null

echo "Builder is ready: $BUILDER_NAME"