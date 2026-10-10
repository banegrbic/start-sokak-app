<?php
/**
 * start.sokak.app — Configuration example
 *
 * OVAJ FAJL JE TEMPLATE. Preimenuj u `config.php` i popuni svojim
 * vrednostima pre deploy-a. config.php je u .gitignore — tvoji
 * kredencijali NIKAD ne idu na GitHub.
 *
    * Za deployment:
 *   1. cp api/config.example.php api/config.php
 *   2. Edituj api/config.php sa svojim vrednostima
 *   3. deploy.sh šalje SAMO api/suggest.php na server, NE config.php
 *   4. config.php ostaje samo na serveru (ne u git-u, ne na GitHub-u)
 *
 * Za lokalni development: napravi api/config.php sa test vrednostima.
 */

// ===== OBAVEZNO =====

// Tvoja email adresa na koju stižu predlozi linkova
$TO_EMAIL    = 'your-email@example.com';

// Email adresa sa koje se šalje (mora postojati na tvom domenu/hostingu)
// Većina cPanel naloga ima email nalog vezan za domen.
// Ako nemaš, možeš da koristiš tvoj lični Gmail sa SMTP autentikacijom.
$FROM_EMAIL  = 'noreply@your-domain.com';

// Ime pošiljaoca (prikazuje se u inbox-u primaoca)
$FROM_NAME   = 'start.sokak.app';

// Subject prefix za email notifikacije
$SUBJECT     = '[start.sokak.app] Novi predlog linka';

// ===== OPCIONO =====

// Putanja do log fajla (van public_html, world-writable na shared hostingu)
// Na cPanel-u PHP web user obično NE MOŽE da piše u public_html/.
// Preporuka: /tmp/ je uvek world-writable. Ako koristiš VPS, stavi u
// /var/log/ tvoje aplikacije.
$LOG_FILE    = '/tmp/start-sokak-app-suggestions.log';

// Anti-spam: minimalno vreme (u sekundama) od otvaranja modala do submita.
// Kraće od ovoga = bot. 2 sekunde je razumno za ljude.
$MIN_SUBMIT_SECONDS = 2;

// Maksimalna dužina URL-a (karaktera). Štiti od DoS-a.
$MAX_URL_LEN  = 500;
