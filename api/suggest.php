<?php
/**
 * start.sokak.app — Suggest Link API
 *
 * Prima JSON POST { url, name, description, email, _hp, _ts } sa index.html,
 * validira, salje email na adresu definisanu u api/config.php (NIJE u git-u)
 * i loguje u $LOG_FILE.
 *
 * Anti-spam:
 *   - Honeypot polje _hp: botovi popunjavaju, ljudi ne vide (display:none)
 *   - Timing: forma postoji bar $MIN_SUBMIT_SECONDS sekundi pre submita (prebrzo = bot)
 *
 * Sigurnost:
 *   - Content-Type mora biti application/json
 *   - Sve ulazne vrednosti se sanitizuju (HTML specijal karakteri escape-ovani)
 *   - URL validacija (scheme mora biti http/https, validan host, SSRF zaštita)
 *   - Email opciona, ako postoji mora biti validan
 *   - Output je uvek JSON, nikad HTML
 *
 * Setup (jednom, na serveru):
 *   1. cp api/config.example.php api/config.php
 *   2. Edituj api/config.php sa svojim email-om i SMTP podacima
 *   3. config.php NIKAD ne ide u git (vidi .gitignore)
 *
 * Fajl je 1:1 mapiran na server u `~/start.sokak.app/api/suggest.php`.
 * NE stavljati u /public_html/ root jer bi bio pristupacan na celom sajtu.
 */

// ===== CONFIG =====
// Konfiguracija se ucitava iz api/config.php (NIJE u git-u — vidi .gitignore).
// Ako config.php ne postoji, koriste se bezbedni placeholder-i (deployment
// ce fail-ovati u tom slucaju, sto je zeljeno ponasanje — bolje da skripta
// jasno signalizira problem nego da tiho salje na pogresan email).
$CONFIG_FILE = __DIR__ . '/config.php';
if (file_exists($CONFIG_FILE)) {
    require_once $CONFIG_FILE;
}

// Bezbedni default-i (override-ovani iz config.php ako postoji)
$TO_EMAIL     = isset($TO_EMAIL)     ? $TO_EMAIL     : 'configure-me@example.com';
$FROM_EMAIL   = isset($FROM_EMAIL)   ? $FROM_EMAIL   : 'noreply@example.com';
$FROM_NAME    = isset($FROM_NAME)    ? $FROM_NAME    : 'start.sokak.app';
$SUBJECT      = isset($SUBJECT)      ? $SUBJECT      : '[start.sokak.app] Novi predlog linka';
$LOG_FILE     = isset($LOG_FILE)     ? $LOG_FILE     : '/tmp/start-sokak-app-suggestions.log';
$MIN_SUBMIT_SECONDS = isset($MIN_SUBMIT_SECONDS) ? $MIN_SUBMIT_SECONDS : 2;
$MAX_URL_LEN  = isset($MAX_URL_LEN)  ? $MAX_URL_LEN  : 500;
$MAX_NAME_LEN = isset($MAX_NAME_LEN) ? $MAX_NAME_LEN : 80;
$MAX_DESC_LEN = isset($MAX_DESC_LEN) ? $MAX_DESC_LEN : 500;
$MAX_EMAIL_LEN = isset($MAX_EMAIL_LEN) ? $MAX_EMAIL_LEN : 120;

// Sigurnosna provera: ako config NIJE ucitan, zaustavi pre slanja email-a.
// Ovo sprecava tiho slanje na placeholder adresu ako neko zaboravi da
// konfigurise pre deploy-a.
if (!file_exists($CONFIG_FILE)) {
    error_log('[start.sokak.app suggest] config.php ne postoji na serveru — predlog nije poslat. Pogledaj api/config.example.php za setup.');
    header('Content-Type: application/json; charset=utf-8');
    http_response_code(503);
    echo json_encode([
        'ok' => false,
        'error' => 'API nije konfigurisan. Administrator: kopiraj api/config.example.php u api/config.php i popuni vrednosti.'
    ]);
    exit;
}

// ===== SETUP: uvek vrati JSON =====
header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');

// ===== HELPERS =====
function respond_error($message, $code = 400) {
    http_response_code($code);
    echo json_encode(['ok' => false, 'error' => $message]);
    exit;
}

function respond_ok() {
    echo json_encode(['ok' => true]);
    exit;
}

// ===== 1. METODA: samo POST =====
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond_error('Samo POST metoda je dozvoljena.', 405);
}

// ===== 2. BODY: parsiraj JSON =====
$raw = file_get_contents('php://input');
if ($raw === false || $raw === '') {
    respond_error('Prazan body.', 400);
}
$data = json_decode($raw, true);
if (!is_array($data)) {
    respond_error('Nevalidan JSON.', 400);
}

// ===== 3. HONEYPOT: ako _hp nije prazan, bot =====
$honeypot = isset($data['_hp']) ? trim((string)$data['_hp']) : '';
if ($honeypot !== '') {
    // Tiho "ok" vracamo botu da misli da je prosao, ali ne saljemo mejl
    error_log('[start.sokak.app suggest] Honeypot triggered from IP ' . ($_SERVER['REMOTE_ADDR'] ?? '?'));
    respond_ok();
}

// ===== 4. TIMING: prebrz submit = bot =====
$ts = isset($data['_ts']) ? (int)$data['_ts'] : 0;
if ($ts > 0) {
    $elapsed = time() - $ts;
    if ($elapsed >= 0 && $elapsed < $MIN_SUBMIT_SECONDS) {
        error_log('[start.sokak.app suggest] Timing fail (' . $elapsed . 's) from IP ' . ($_SERVER['REMOTE_ADDR'] ?? '?'));
        respond_ok(); // tiho, kao da je ok
    }
}

// ===== 5. URL: obavezan, validan, http/https =====
$url = isset($data['url']) ? trim((string)$data['url']) : '';
if ($url === '') {
    respond_error('URL je obavezan.');
}
if (mb_strlen($url) > $MAX_URL_LEN) {
    respond_error('URL je predugačak (max ' . $MAX_URL_LEN . ' karaktera).');
}
if (!preg_match('#^https?://#i', $url)) {
    respond_error('URL mora pocinjati sa http:// ili https://');
}
$parsed = parse_url($url);
if (!$parsed || empty($parsed['host']) || !preg_match('/^[a-z0-9.\-]+(\.[a-z]{2,})$/i', $parsed['host'])) {
    respond_error('URL nije ispravan (nema validan host).');
}
// Blokiramo lokalne/private hostove (SSRF zastita)
$host = strtolower($parsed['host']);
if (in_array($host, ['localhost', '127.0.0.1', '0.0.0.0'], true)) {
    respond_error('URL nije dozvoljen.');
}
if (preg_match('/^(10\.|172\.(1[6-9]|2\d|3[01])\.|192\.168\.|169\.254\.)/', $host)) {
    respond_error('URL nije dozvoljen.');
}

// ===== 6. NAME: opcion, max len =====
$name = isset($data['name']) ? trim((string)$data['name']) : '';
if ($name !== '' && mb_strlen($name) > $MAX_NAME_LEN) {
    respond_error('Naziv je predugacak (max ' . $MAX_NAME_LEN . ' karaktera).');
}

// ===== 7. DESCRIPTION: opcion, max len =====
$description = isset($data['description']) ? trim((string)$data['description']) : '';
if ($description !== '' && mb_strlen($description) > $MAX_DESC_LEN) {
    respond_error('Opis je predugacak (max ' . $MAX_DESC_LEN . ' karaktera).');
}

// ===== 8. EMAIL: opcion, validan format =====
$email = isset($data['email']) ? trim((string)$data['email']) : '';
if ($email !== '') {
    if (mb_strlen($email) > $MAX_EMAIL_LEN) {
        respond_error('Email je predugacak.');
    }
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        respond_error('Email nije ispravan.');
    }
}

// ===== 9. SANITIZACIJA za HTML email =====
$safe_url  = htmlspecialchars($url, ENT_QUOTES | ENT_HTML5, 'UTF-8');
$safe_name = htmlspecialchars($name, ENT_QUOTES | ENT_HTML5, 'UTF-8');
$safe_desc = nl2br(htmlspecialchars($description, ENT_QUOTES | ENT_HTML5, 'UTF-8'));
$safe_email = htmlspecialchars($email, ENT_QUOTES | ENT_HTML5, 'UTF-8');
$safe_ip   = htmlspecialchars($_SERVER['REMOTE_ADDR'] ?? 'nepoznat', ENT_QUOTES, 'UTF-8');
$safe_ua   = htmlspecialchars($_SERVER['HTTP_USER_AGENT'] ?? 'nepoznat', ENT_QUOTES, 'UTF-8');
$now       = date('Y-m-d H:i:s');

// ===== 10. HTML EMAIL BODY =====
$body_html = <<<HTML
<!DOCTYPE html>
<html lang="sr">
<head><meta charset="UTF-8"></head>
<body style="font-family: -apple-system, system-ui, sans-serif; color: #222; max-width: 600px;">
<h2 style="color: #4a90e2; margin-top: 0;">Novi predlog linka — start.sokak.app</h2>

<table cellpadding="8" cellspacing="0" style="border-collapse: collapse; width: 100%;">
  <tr><td style="background:#f5f5f5; font-weight:600; width:100px;">URL</td>
      <td><a href="$safe_url">$safe_url</a></td></tr>
  <tr><td style="background:#f5f5f5; font-weight:600;">Naziv</td>
      <td>$safe_name <span style="color:#999;">(prazno)</span></td></tr>
  <tr><td style="background:#f5f5f5; font-weight:600; vertical-align:top;">Opis</td>
      <td>$safe_desc <span style="color:#999;">(prazno)</span></td></tr>
  <tr><td style="background:#f5f5f5; font-weight:600;">Email</td>
      <td>$safe_email <span style="color:#999;">(nije ostavljen)</span></td></tr>
</table>

<hr style="border:none; border-top:1px solid #ddd; margin:20px 0;">
<p style="color:#666; font-size:12px;">
  Vreme: $now<br>
  IP: $safe_ip<br>
  Browser: $safe_ua
</p>
</body>
</html>
HTML;

// Plain-text verzija (za email klijente koji ne prikazuju HTML)
$body_text = "Novi predlog linka — start.sokak.app\n\n"
           . "URL: $url\n"
           . "Naziv: " . ($name ?: '(prazno)') . "\n"
           . "Opis: " . ($description ?: '(prazno)') . "\n"
           . "Email: " . ($email ?: '(nije ostavljen)') . "\n"
           . "\n--\n"
           . "Vreme: $now\n"
           . "IP: " . ($_SERVER['REMOTE_ADDR'] ?? 'nepoznat') . "\n"
           . "Browser: " . ($_SERVER['HTTP_USER_AGENT'] ?? 'nepoznat') . "\n";

// ===== 11. EMAIL HEADERI =====
$boundary = md5(uniqid(time()));
$headers  = "From: $FROM_NAME <$FROM_EMAIL>\r\n";
$headers .= "Reply-To: " . ($email ?: $FROM_EMAIL) . "\r\n";
$headers .= "MIME-Version: 1.0\r\n";
$headers .= "Content-Type: multipart/alternative; boundary=\"$boundary\"\r\n";
$headers .= "X-Mailer: start.sokak.app/1.0\r\n";

// multipart/alternative body
$body_full = "--$boundary\r\n";
$body_full .= "Content-Type: text/plain; charset=utf-8\r\n\r\n";
$body_full .= $body_text . "\r\n\r\n";
$body_full .= "--$boundary\r\n";
$body_full .= "Content-Type: text/html; charset=utf-8\r\n\r\n";
$body_full .= $body_html . "\r\n\r\n";
$body_full .= "--$boundary--\r\n";

// ===== 12. POSALJI MEJL =====
$sent = @mail($TO_EMAIL, $SUBJECT, $body_full, $headers);
if (!$sent) {
    error_log("[start.sokak.app suggest] mail() FAILED for URL=$url");
    respond_error('Slanje mejla nije uspelo. Pokusajte ponovo.', 500);
}

// ===== 13. LOG u fajl (backup, ne zavisi od email deliverability) =====
$log_line = sprintf(
    "[%s] ip=%s url=%s name=%s desc=%s email=%s ua=%s\n",
    $now,
    $_SERVER['REMOTE_ADDR'] ?? '?',
    $url,
    $name,
    str_replace(["\r", "\n"], ' ', $description),
    $email,
    $_SERVER['HTTP_USER_AGENT'] ?? '?'
);
@file_put_contents($LOG_FILE, $log_line, FILE_APPEND | LOCK_EX);

// ===== 14. SUCCESS =====
respond_ok();
