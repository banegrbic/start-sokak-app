#!/bin/bash
# Kompletni KulaWireless deploy workflow u jednoj komandi:
# 1. Bump cache-busting ?v= u index.html (timestamp YYYYMMDDHHMM)
# 2. git add + commit + push
# 3. SCP fajlova na cPanel server
# 4. curl verifikacija da novi fajl stiže sa novom verzijom
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
REMOTE_DIR="~/tata.lukasplayroom.com/public/KulaWireless"
LIVE_URL="https://tata.lukasplayroom.com/public/KulaWireless/"

# Fajlovi za deploy (bez secrets/, .git/, backup-ova)
FILES_TO_DEPLOY=(
  "index.html"
  "responsive.css"
  "api/suggest.php"
  "favicon-16.png"
  "favicon-32.png"
  "favicon-64.png"
  "favicon.svg"
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

# ========== 3. SCP NA SERVER ==========
echo "→ SCP fajlova na $SSH_USER@$SSH_HOST:$REMOTE_DIR"
for f in "${FILES_TO_DEPLOY[@]}"; do
  if [ -f "$PROJECT_DIR/$f" ]; then
    scp -i "$SSH_KEY" -o BatchMode=yes "$PROJECT_DIR/$f" "$SSH_USER@$SSH_HOST:$REMOTE_DIR/$f"
    echo "  ✓ $f"
  else
    echo "  ⚠ $f ne postoji lokalno, preskačem"
  fi
done
echo

# ========== 4. VERIFIKACIJA ==========
echo "→ curl verifikacija live URL-a"
# Sačekaj 1s da server opsluži nov fajl
sleep 1
# Izvuci novu verziju iz lokalnog fajla
NEW_V=$(grep -oE '\?v=[0-9a-z]+' "$PROJECT_DIR/index.html" | head -1)
echo "  očekivana verzija: $NEW_V"
echo

# Proveri da server vraća HTML koji referencira novu verziju
SERVER_HEADERS=$(curl -sS -I "$LIVE_URL" 2>&1 || echo "GREŠKA: curl nije uspeo")
echo "  Server response:"
echo "$SERVER_HEADERS" | head -5
echo

# Proveri da HTML koji server vraća sadrži novu verziju
SERVER_HTML=$(curl -sS "$LIVE_URL" 2>&1 || echo "GREŠKA")
if echo "$SERVER_HTML" | grep -q "$NEW_V"; then
  echo "  ✓ Server vraća HTML sa novom verzijom $NEW_V"
else
  echo "  ⚠ Server NE vraća novu verziju (možda CDN/proxy keš)"
  echo "    Očekivano u HTML-u: $NEW_V"
  echo "    Stvarno sadržano: $(echo "$SERVER_HTML" | grep -oE 'responsive\.css\?v=[0-9a-z]+' | head -1)"
fi
echo

echo "✓ Deploy završen"
echo "  Live URL: $LIVE_URL"
echo "  Verzija:  $NEW_V"
echo
echo "  Napomena: korisnik treba da uradi hard refresh (Ctrl+Shift+R)"
echo "  ili doda ?v=N na kraj URL-a da bi browser učitao novu verziju."
