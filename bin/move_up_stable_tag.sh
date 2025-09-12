#!/bin/bash

# Ensure the script exits on errors
set -e

# Check for input arguments
if [ "$#" -ne 1 ]; then
  echo "Usage: ./move_up_stable_tag.sh <target-tag-without-v>"
  exit 1
fi

SOURCE_TAG="$1"
ALIAS_TAG="stable"

# List of images to retag
IMAGES=(
  "pglombardo/pwpush"
  "pglombardo/pwpush-worker"
  "pglombardo/pwpush-public-gateway"
)

for IMAGE in "${IMAGES[@]}"; do
  echo "Retrieving digests for ${IMAGE}:${SOURCE_TAG}..."

  # Use docker manifest inspect to parse platform-specific digests
  MANIFEST_JSON=$(docker manifest inspect "${IMAGE}:${SOURCE_TAG}")

  AMD64_DIGEST=$(echo "${MANIFEST_JSON}" | jq -r '.manifests[] | select(.platform.architecture == "amd64") | .digest' | head -n 1)
  ARM64_DIGEST=$(echo "${MANIFEST_JSON}" | jq -r '.manifests[] | select(.platform.architecture == "arm64") | .digest' | head -n 1)

  if [ -z "${AMD64_DIGEST}" ] || [ -z "${ARM64_DIGEST}" ]; then
    echo "Error: Could not retrieve digests for ${IMAGE}:${SOURCE_TAG}"
    exit 1
  fi

  echo "Removing existing stable tag if it exists..."
  docker manifest rm "${IMAGE}:${ALIAS_TAG}" || true

  echo "Creating manifest for ${IMAGE}:${ALIAS_TAG}..."
  docker manifest create "${IMAGE}:${ALIAS_TAG}" \
    "${IMAGE}@${AMD64_DIGEST}" \
    "${IMAGE}@${ARM64_DIGEST}"

  echo "Annotating platforms for ${IMAGE}:${ALIAS_TAG}..."
  docker manifest annotate "${IMAGE}:${ALIAS_TAG}" "${IMAGE}@${AMD64_DIGEST}" --arch amd64
  docker manifest annotate "${IMAGE}:${ALIAS_TAG}" "${IMAGE}@${ARM64_DIGEST}" --arch arm64

  echo "Pushing manifest for ${IMAGE}:${ALIAS_TAG}..."
  docker manifest push --purge "${IMAGE}:${ALIAS_TAG}"
done

echo "Checking out version tag: v${SOURCE_TAG}"
git checkout "v${SOURCE_TAG}"

echo "Deleting the 'stable' tag from git: local and remote"
git tag -d "${ALIAS_TAG}"
git push oss --delete "${ALIAS_TAG}"

echo "Moving stable tag to new version: v${SOURCE_TAG}"
git tag "${ALIAS_TAG}"
git push oss "${ALIAS_TAG}"

echo "v${SOURCE_TAG} has been tagged as '${ALIAS_TAG}' successfully."

echo ""
echo "=========================================="
echo "CONTENT COPY (ready to paste):"
echo "=========================================="
echo ""
echo "The Docker \"stable\" tag has been moved up to v${SOURCE_TAG}"
echo ""
echo "https://github.com/pglombardo/PasswordPusher/releases/tag/v${SOURCE_TAG}"
echo ""
echo "=========================================="
