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
  echo "Pointing ${IMAGE}:${ALIAS_TAG} at ${IMAGE}:${SOURCE_TAG} (all platforms)..."
  # Copy the full multi-arch manifest list (amd64 + arm64 + attestations)
  docker buildx imagetools create -t "${IMAGE}:${ALIAS_TAG}" "${IMAGE}:${SOURCE_TAG}"
  docker buildx imagetools inspect "${IMAGE}:${ALIAS_TAG}"
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
echo "The OSS Docker \"stable\" tag has been moved up to v${SOURCE_TAG}"
echo ""
echo "https://github.com/pglombardo/PasswordPusher/releases/tag/v${SOURCE_TAG}"
echo ""
echo "=========================================="
