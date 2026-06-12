# KulaWireless — TODO

## Poznati problemi (za kasnije)

### Pinterest layout — koristimo workaround, nije pravi masonry

- **Trenutno stanje (8.6.2026)**: CSS Grid 2-kolone sa defaultnim `align-items: stretch`. Kartice u istom redu su iste visine, manja dobija prazan prostor dole.
- **Status**: Korisnik odobrio ovaj workaround. Radi dobro, vizuelno uredno, ali nije Pinterest.
- **Pravi Pinterest masonry (nedovršeno)**: 
  - Pokušan Masonry.js (CDN `masonry-layout@4.2.2`) — bagovao u test browseru (postavljao `position: absolute` ali ne i `transform`)
  - Pokušan CSS Grid + `grid-auto-flow: dense` — radio ali korisnik rekao "nije baš kao Pinterest"
  - Pokušan CSS columns sa `break-inside: avoid` — imao preklapanja
- **Moguća poboljšanja** (kad korisnik bude hteo):
  - Masonry.js ponovo — u pravom Chrome-u možda radi (bagovalo u test browseru)
  - JavaScript grid library (Brick.js, Gridstack)
  - Hibrid: CSS grid za osnovni layout + JS za fino podešavanje

### ~~Drag kategorija na mobilnom — ne radi~~ REŠENO 8.6.2026

- Raniji problem: Sortable.js sa `delay: 50` je preuzimao touchstart event i blokirao normalan tap.
- Fix: dodat `onMove` callback koji vraća `false` ako je tap na `<a>` element. Sortable ne ulazi u drag mode za tap.
- Status: KORISNIK POTVRDIO DA RADI (8.6.2026).

### ~~Pinterest layout — nije savršen~~ PRIHVAĆENO KAO WORKAROUND (12.6.2026)

- Korisnik kaže "radi dobro, vizuelno uredno, ostavi za sada" — preskoči.
- Status: KORISNIK PRIHVATIO.

### Novi feature: "Predloži link" dugme (12.6.2026)

- Dugme u toolbar-u pored "Dodaj link" (žuta boja da se razlikuje).
- Modal sa formom: URL (obavezno), Naziv, Opis, Email (opciono).
- PHP backend `api/suggest.php` šalje email na `bane.grbic@gmail.com` (preko cPanel mail()).
- Anti-spam: honeypot polje + timing provera (2s minimum).
- Log: `/tmp/kulawireless-suggestions.log` (van public_html, world-writable).
- Validacija: URL mora biti http/https sa validnim hostom, SSRF zaštita (blokira localhost/private IP).
- Browser submit testiran end-to-end (12.6.2026), log potvrđen.

### Link cleanup run #1 (12.6.2026)

- **Healthcheck metod**: 123 unique eksternih linkova, paralelan curl (20 istovremenih) + browser/wget/dns verifikacija sumnjivih.
- **Izbačeno**: 24sata.rs (preusmeren na vijetnamski piratski streaming), netkolumne.com (preusmeren na ASTROSLOT kockanje), TV program/aladin.info (korisnik rekao da ga izbaci uprkos 200 statusu).
- **Update-ovano**: yts.ag→yts.bz, divx-titlovi.com→titlovi.com, rs.sputniknews.com→sputnikportal.rs, kurir-info.rs→kurir.rs, zurnal.rs→zurnal.politika.rs.
- **Lažno pozitivni** (Cloudflare/anti-bot): rockradio.rs, halooglasi.com, hattrick.org, polovniautomobili.com, istinomer.rs, chat.openai.com, pixabay.com, twitter.com, filehippo.com, brave.com — svi provereni u browser-u, aktivni su.
- **Svaštara ostavljena** — korisnik potvrdio da radi (ja ne vidim zbog Cloudflare zaštite, korisnik vidi normalno).

### Restruktuiranje kategorija (12.6.2026)

**Verzija 1 (isto jutro):**
- "Filmovi i muzika" → "Multimedija" (preimenovana, isti linkovi).
- "Alati i produktivnost" — NOVA (6 linkova: Translate, Drive, Dropbox, Google Maps, Google Photos, FileHippo).
- "Globalni servisi" smanjen sa 14 na 8 (Translate, Drive, Dropbox, Maps, Photos, FileHippo su prešli u Alati).
- "Pretraga i pošta" proširena sa 11 na 13 (dodati Perplexity i Claude, ChatGPT URL fiksiran na chatgpt.com).
- "Kula / Vrbas" IZBAČENA — projekat je usmeren na sve korisnike u Srbiji.
- Pravilo za buduće izmene: Ako isti link postoji u 2 kategorije, "Pretraga i pošta" ima prioritet za čuvanje.

**Verzija 2 (12.6.2026, kasnije):**
- **10 kategorija** + Custom linkovi (uvek vidljiv) + Moji linkovi
- **Raspored u parovima** (2-kolonski grid desktop, 1-kolona mobilni):
  - Par 1: Moji linkovi (★) | Custom linkovi (＋) — prazan ali vidljiv
  - Par 2: Pretraga, pošta, AI (🔍) | Društvene mreže (👥)
  - Par 3: Mediji (📰) | Portali (📰)
  - Par 4: Globalni servisi (🌐) | Domaći servisi (🇷🇸)
  - Par 5: Multimedija (🎬) | Razno (📦)
  - Par 6: Zabava (🎮) | Alati i produktivnost (🛠️)
- **Emoji ikone** (Unicode) levo od svakog naslova
- **Subtitle** italic manji tekst: "Nezavisni i slobodni mediji" (Mediji), "Uključuje tabloidne news portale" (Portali) — na mobilnom display:block ispod
- **CSS padding** ispod poslednjeg reda (40px), 18px razmak između kartica
- **YouTube** premešten iz Pretraga u Multimedija
- **Euronews.rs, Politika, RT** premešteni iz Mediji u Portali
- **Alo, Kurir** izbačeni iz Portala
- **Live Score** premešten iz Zabava u Globalni servisi
- **Translate, Google Maps, Google Photos** premešteni iz Alati u Globalni servisi
- **renderCustom()** refaktorisana: sekcija se NE briše kada je prazna, samo prikazuje "Dodaj link dugmetom 'Dodaj link' iznad"
- **Commit:** `311b678` (2 files, 166 ins, 112 del)

### Custom linkovi sakrivanje fix (12.6.2026)

- **Bug**: `applySavedHidden()` se zvao na load-u, ali Custom sekcija se kreira dinamički u `renderCustom()` KASNIJE. Tako da hidden state nikad nije bio primenjen na Custom.
- **Fix**: posle `ensureCustomSection()` u `renderCustom()`, proveri da li je sekcija tek kreirana — ako jeste, primeni hidden state iz localStorage i update-uj ikonice.
- **Rezultat**: Custom linkovi se ponašaju isto kao i druge kategorije — 👁 sakriva, "Prikaži sve" vraća, refresh pamti.
- **Commit:** `830eb6a` (1 file, 10 ins)

### Mobilni hamburger meni (12.6.2026)

- **Na mobilnom/tabletu (<900px)**: 4 opcije (Dodaj link, Predloži link, Prikaži sve, Obriši Moje) sakrivene iza ☰ hamburger dugmeta. Search polje i dark/light mode ostaju vidljivi.
- **CSS klase**: `.desktop-only` sakriven na <900px, `.mobile-only` prikazan na <900px, `.hamburger-btn` prikazan na <900px.
- **Akcije menija**: zatvori meni, pa pozovi `openAddCustom()` / `openSuggest()` / `showAllBtn.click()` / `resetFavorites.click()`.
- **Zatvaranje**: klik na ☰ (toggle), klik van menija, ili akcija.
- **Verifikacija**: desktop sakriven hamburger (display:none), mobilni vidi ☰; testirano open/close, akcija "Dodaj link" otvara modal.
- **Commit:** `90eaf26` (2 files, 210 ins, 10 del)

### Mobilni theme toggle u toolbar-u (12.6.2026, fix)

- **Problem**: Stari `<button class="theme-toggle">` je `position: fixed; top:16; right:16` u gornjem desnom uglu, fiksno vidljiv na svim viewport-ovima. Na mobilnom (<900px) je prekrivao hamburger ☰ u istom prostoru.
- **Rešenje**:
  - HTML: Dodat `<span id="themeToggleWrapper2">` sa `<button class="theme-toggle-mobile">` unutar toolbara, između search i hamburger.
  - CSS: Stari `.theme-toggle` → `display: none !important` na <900px. Novi wrapper → `display: inline-flex` na <900px, `display: none` na desktopu.
  - JS: Mobile theme dugme okida `mainBtn.click()` (poziva isti handler kao stari #themeToggle), MutationObserver prati `data-theme` atribut i ažurira ikonu (☀️/🌙).
- **DOM order bug**: Početno IIFE postavljen na vrhu body-ja, ALI `#themeToggleWrapper2` se nalazi u toolbar-u niže — handler se nikad ne bi ni instalirao. Rešeno: premešten na kraj body-ja (posle toolbar DOM-a).
- **Lekcija za budućnost**: Ako skripta zavisi od elementa koji se pojavi kasnije u dokumentu, staviti skriptu POSLE tog elementa ili koristiti `DOMContentLoaded`.
- **Verifikacija** (CSS override simulira mobilni): search (x=14) → theme wrapper (x=1163, 40×36) → hamburger (x=1211, 40×36). Redosled tačan, razmaci 8px.
- **Commit-ovi:** `55b6a8c` (HTML+CSS), `ba6864c` (CSS base stilovi van media query), `ea61779` (DOM order fix).

### ⚠️ Deploy lekcija (12.6.2026, kritično)

- **Problem**: `rsync --delete` sa lokalnog projektnog foldera na server OBRIŠE sve što nije u source direktorijumu — uključujući favicon PNG fajlove, .htaccess, error_log i stare backup foldere na serveru.
- **Posledica (jednom se desilo)**: Favicon PNG fajlovi obrisani sa servera. Vraćeni ručno preko `scp` iz lokalnog source-a.
- **Pravilo za ubuduće**: Nikada ne koristiti `--delete` flag na rsync za KulaWireless deploy. Koristiti `scp` za pojedinačne fajlove, ili rsync bez `--delete` uz ručnu proveru šta se šalje.

### Planirano (kad korisnik bude hteo)

- **Email format/template** — trenutno plain HTML sa tabelom, može lepši branded template.
- **Notifikacija korisniku** — posle uspešnog submita prikaže "Hvala, predlog je poslat" (već radi kao toast).
- **Rate limiting** — trenutno samo timing + honeypot. Ako bude spam problema, dodati IP-based rate limit (npr. 5 submita/sat/IP).

---

## Napomene

- Ovaj fajl se commit-uje na GitHub zajedno sa kodom.
- Korisnik odlučuje kada se stavka adresira.
- Kad se stavka reši, prebaci u CHANGELOG ili obriši.
