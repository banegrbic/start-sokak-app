#!/bin/bash
# Bump cache-busting ?v= query string u index.html
# Format: ?v=YYYYMMDDHHMM (12 cifara, sortirano po vremenu)
#
# Upotreba:
#   ./scripts/bump-version.sh           # koristi trenutni timestamp
#   ./scripts/bump-version.sh "v=2024"  # custom verzija (za ručni override)
#
# Ne radi commit, ne radi push — samo menja fajl. Korisno za debug
# ili kad hoces da bump-ujes verziju pre nego sto radis izmene.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INDEX="$SCRIPT_DIR/../index.html"

if [ ! -f "$INDEX" ]; then
  echo "ERROR: $INDEX ne postoji"
  exit 1
fi

if [ -n "$1" ]; then
  NEW_V="$1"
else
  NEW_V="v=$(date +%Y%m%d%H%M)"
fi

# Izvuci SAMO ?v=... deo (bez "responsive.css" prefiksa)
OLD_V_FULL=$(grep -oE 'responsive\.css\?v=[0-9a-z]+' "$INDEX" | head -1 || echo "")
OLD_V_QS=$(echo "$OLD_V_FULL" | grep -oE '\?v=[0-9a-z]+' || echo "")

if [ -z "$OLD_V_QS" ]; then
  echo "ERROR: nisam našao ?v=... u $INDEX"
  exit 1
fi

NEW_QS="?$NEW_V"

if [ "$OLD_V_QS" = "$NEW_QS" ]; then
  echo "Već je na $NEW_QS, nema promene"
  exit 0
fi

# Cross-platform sed (BSD/GNU): pravi backup, menja u mestu
sed -i.bak "s|$OLD_V_QS|$NEW_QS|g" "$INDEX"
rm -f "$INDEX.bak"

echo "✓ $OLD_V_QS → $NEW_QS"
