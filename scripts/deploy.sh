#!/bin/bash
# Kompletni start.sokak.app (ex-KulaWireless) deploy workflow u jednoj komandi:
# 1. Bump cache-busting ?v= u index.html (timestamp YYYYMMDDHHMM)
# 2. git add + commit + push
# 3. SCP fajlova na cPanel server (oba domena)
# 4. curl verifikacija da novi fajl stiže sa novom verzijom (oba domena)
#
# Upotreba:
#   ./scripts/deploy.sh "Fix: opis izmene"
#
# Ako nemaš argumenata, koristi generički "Deploy" commit message.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

# ========== KONFIGURACIJA ==========
SSH_KEY="$PROJECT_DIR/secrets/sokak-app-deploy"
SSH_USER="lukasplayroom"
SSH_HOST="194.146.59.203"

# Glavni (primarni) deployment target
REMOTE_DIR_PRIMARY="~/start.sokak.app"
LIVE_URL_PRIMARY="https://start.sokak.app/"

# Sekundarni deployment target (kompatibilnost sa starim URL-om)
REMOTE_DIR_LEGACY="~/tata.lukasplayroom.com/public/KulaWireless"
LIVE_URL_LEGACY="https://tata.lukasplayroom.com/public/KulaWireless/"

# Fajlovi za deploy (bez secrets/, .git/, backup-ova)
FILES_TO_DEPLOY=(
  "index.html"
  "responsive.css"
  "api/suggest.php"
  "favicon-16.png"
  "favicon-32.png"
  "favicon-64.png"
  "favicon.svg"
  "apple-touch-icon-precomposed.png"
  "TODO.md"
)

# ========== 1. BUMP VERZIJA ==========
echo "→ Bump cache-busting ?v= u index.html"
bash "$SCRIPT_DIR/bump-version.sh"
echo

# ========== 2. GIT COMMIT + PUSH ==========
COMMIT_MSG="${1:-Deploy}"
echo "→ git add + commit: \"$COMMIT_MSG\""
git add -A
if git diff --cached --quiet; then
  echo "  (nema izmena za commit, preskačem commit + push)"
else
  git commit -m "$COMMIT_MSG"
  echo "→ git push"
  git push origin master
fi
echo

# ========== 3. SCP NA SERVER (OBA DOMENA) ==========
deploy_to() {
  local REMOTE_DIR="$1"
  local LABEL="$2"
  echo "→ SCP fajlova na $SSH_USER@$SSH_HOST:$REMOTE_DIR  ($LABEL)"
  # Osiguraj da api/ direktorijum postoji
  ssh -i "$SSH_KEY" -o BatchMode=yes "$SSH_USER@$SSH_HOST" "mkdir -p $REMOTE_DIR/api" 2>/dev/null || true
  for f in "${FILES_TO_DEPLOY[@]}"; do
    if [ -f "$PROJECT_DIR/$f" ]; then
      scp -i "$SSH_KEY" -o BatchMode=yes "$PROJECT_DIR/$f" "$SSH_USER@$SSH_HOST:$REMOTE_DIR/$f" 2>/dev/null
      echo "  ✓ $f"
    else
      echo "  ⚠ $f ne postoji lokalno, preskačem"
    fi
  done
  # Postavi executable bit na PHP
  ssh -i "$SSH_KEY" -o BatchMode=yes "$SSH_USER@$SSH_HOST" "chmod 755 $REMOTE_DIR/api/suggest.php 2>/dev/null" || true
  echo
}

deploy_to "$REMOTE_DIR_PRIMARY" "PRIMARNI: start.sokak.app"
deploy_to "$REMOTE_DIR_LEGACY" "LEGACY: tata.lukasplayroom.com"

# ========== 4. VERIFIKACIJA ==========
verify_url() {
  local LIVE_URL="$1"
  local LABEL="$2"
  echo "→ curl verifikacija: $LIVE_URL  ($LABEL)"
  # Izvuci novu verziju iz lokalnog fajla (samo za responsive.css, NE apple-touch-icon)
  local NEW_V=$(grep -oE 'responsive\.css\?v=[0-9a-z]+' "$PROJECT_DIR/index.html" | head -1 | sed 's/responsive\.css//')
  echo "  očekivana verzija: $NEW_V"

  # Proveri HTML koji server vraća
  local SERVER_HTML=$(curl -sS "$LIVE_URL" 2>&1 || echo "GREŠKA")
  local SERVER_CSS_V=$(echo "$SERVER_HTML" | grep -oE 'responsive\.css\?v=[0-9a-z]+' | head -1 | sed 's/responsive\.css//' || echo "")
  if [ -n "$SERVER_CSS_V" ] && [ "$SERVER_CSS_V" = "$NEW_V" ]; then
    echo "  ✓ Server vraća HTML sa novom verzijom$NEW_V"
  else
    echo "  ⚠ Server NE vraća novu verziju (možda CDN/proxy keš)"
    echo "    Očekivano u HTML-u:$NEW_V"
    echo "    Stvarno sadržano:   $SERVER_CSS_V"
  fi
  echo
}

verify_url "$LIVE_URL_PRIMARY" "PRIMARNI"
verify_url "$LIVE_URL_LEGACY" "LEGACY"

echo "✓ Deploy završen"
echo "  Primarni URL:  $LIVE_URL_PRIMARY"
echo "  Legacy URL:    $LIVE_URL_LEGACY"
NEW_V=$(grep -oE 'responsive\.css\?v=[0-9a-z]+' "$PROJECT_DIR/index.html" | head -1 | sed 's/responsive\.css//')
echo "  Verzija:$NEW_V"
echo
echo "  Napomena: korisnik treba da uradi hard refresh (Ctrl+Shift+R)"
echo "  ili doda ?v=N na kraj URL-a da bi browser učitao novu verziju."
