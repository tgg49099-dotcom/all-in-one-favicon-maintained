#!/usr/bin/env bash
# =============================================================================
# fetch-original.sh - telecharge le ZIP OFFICIEL du plugin et le decompresse
#
#   usage : bash fetch-original.sh
#
# Le code "original" (non corrige) n'est PAS versionne dans ce depot : il est
# telecharge depuis l'URL officielle de WordPress.org et verifie par son md5.
# C'est ce qui rend la contre-preuve rouge reproductible par un tiers.
#
#   ZIP  : https://downloads.wordpress.org/plugin/all-in-one-favicon.4.8.zip
#   md5  : f4d3146d5aca7def9fd1694a831084cb
# =============================================================================
set -euo pipefail
BASE=${AIOF_BASE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}

SLUG=all-in-one-favicon
VER=4.8
URL="https://downloads.wordpress.org/plugin/${SLUG}.${VER}.zip"
MD5="f4d3146d5aca7def9fd1694a831084cb"
DEST="$BASE/original"
TMP="$BASE/.fetch-original.tmp"

if [ -f "$DEST/$SLUG/${SLUG}.php" ]; then
  echo "[fetch] $DEST/$SLUG est deja present -> rien a faire"
  exit 0
fi

rm -rf "$TMP"; mkdir -p "$TMP"
echo "[fetch] telechargement $URL"
curl -sS -L -o "$TMP/${SLUG}.${VER}.zip" "$URL"
GOT=$(md5sum "$TMP/${SLUG}.${VER}.zip" | cut -d' ' -f1)
if [ "$GOT" != "$MD5" ]; then
  echo "[fetch] ECHEC : md5 $GOT != $MD5 attendu" >&2
  rm -rf "$TMP"
  exit 1
fi
echo "[fetch] md5 OK ($GOT)"
unzip -q -o "$TMP/${SLUG}.${VER}.zip" -d "$TMP/x"
mkdir -p "$DEST"
rm -rf "$DEST/$SLUG"
mv "$TMP/x/$SLUG" "$DEST/$SLUG"
rm -rf "$TMP"
echo "[fetch] code officiel pret dans $DEST/$SLUG"
