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

# ========== KONFIGURACIJA (POPUNI SVOJIM VREDNOSTIMA) ==========
# Ovaj deploy skripta je generički template. Pre prvog pokretanja:
#   1. Napravi secrets/ folder sa svojim SSH ključem (npr. secrets/deploy-key)
#      secrets/ je vec u .gitignore — tvoj kljuc nece biti commit-ovan.
#   2. Promeni SSH_USER, SSH_HOST, REMOTE_DIR_*, LIVE_URL_* dole.
#   3. Za legacy domen (opciono) — postavi na svoj stari URL ili obrisi blok.
#
# Primer: deploy na ~/public_html/ na cPanel hostingu:
#   SSH_USER="tvoj_cpanel_username"
#   SSH_HOST="tvoj.server.com"  (ili IP)
#   REMOTE_DIR_PRIMARY="~/public_html"
#   LIVE_URL_PRIMARY="https://tvoj-domen.com/"

SSH_KEY="$PROJECT_DIR/secrets/deploy-key"
SSH_USER="your-cpanel-username"
SSH_HOST="your-server.com"

# Glavni (primarni) deployment target
REMOTE_DIR_PRIMARY="~/public_html"
LIVE_URL_PRIMARY="https://your-domain.com/"

# Sekundarni deployment target (opciono — za legacy URL / stariji sajt).
# Ako ti ne treba legacy, postavi REMOTE_DIR_LEGACY na isto kao PRIMARY
# ili obrisi deploy_to "$REMOTE_DIR_LEGACY" liniju dole.
REMOTE_DIR_LEGACY="~/public_html-legacy"
LIVE_URL_LEGACY="https://legacy.your-domain.com/"

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
)

# ========== SIGURNOSNA PROVERA ==========
# Ako nisi popunio konfiguraciju, deploy nece ici.
if [ "$SSH_USER" = "your-cpanel-username" ] || [ "$SSH_HOST" = "your-server.com" ]; then
  echo "❌ GREŠKA: deploy.sh nije konfigurisan."
  echo "   Edituj CONFIG sekciju (linije 20-40) sa svojim SSH_USER, SSH_HOST, REMOTE_DIR."
  echo "   Pogledaj README.md → 'Deployment' sekciju za detalje."
  exit 1
fi

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

deploy_to "$REMOTE_DIR_PRIMARY" "PRIMARY"
deploy_to "$REMOTE_DIR_LEGACY" "LEGACY"

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
