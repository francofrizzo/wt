#!/bin/bash
set -e

VERSION="${1:?Usage: ./release.sh <version> (e.g. 0.2.0)}"
TAG="v$VERSION"
REPO="francofrizzo/wt"
TAP_DIR="$(dirname "$0")/../homebrew-tap"

if [ ! -d "$TAP_DIR/.git" ]; then
  echo "Error: homebrew-tap repo not found at $TAP_DIR" >&2
  echo "Clone it alongside this repo: git clone git@github.com:francofrizzo/homebrew-tap.git" >&2
  exit 1
fi

echo "==> Tagging $TAG"
git tag "$TAG"
git push origin "$TAG"

echo "==> Computing SHA256"
SHA=$(curl -sL "https://github.com/$REPO/archive/refs/tags/$TAG.tar.gz" | shasum -a 256 | cut -d' ' -f1)
echo "    $SHA"

echo "==> Updating homebrew-tap formula"
sed -i '' \
  -e "s|url \".*\"|url \"https://github.com/$REPO/archive/refs/tags/$TAG.tar.gz\"|" \
  -e "s|sha256 \".*\"|sha256 \"$SHA\"|" \
  "$TAP_DIR/Formula/wt.rb"

echo "==> Pushing homebrew-tap"
git -C "$TAP_DIR" add Formula/wt.rb
git -C "$TAP_DIR" commit -m "wt $TAG"
git -C "$TAP_DIR" push

echo ""
echo "Done! Released wt $TAG"
echo "Users can run: brew upgrade wt"
