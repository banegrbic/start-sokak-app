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

### Planirano (kad korisnik bude hteo)

- **Email format/template** — trenutno plain HTML sa tabelom, može lepši branded template.
- **Notifikacija korisniku** — posle uspešnog submita prikaže "Hvala, predlog je poslat" (već radi kao toast).
- **Rate limiting** — trenutno samo timing + honeypot. Ako bude spam problema, dodati IP-based rate limit (npr. 5 submita/sat/IP).

---

## Napomene

- Ovaj fajl se commit-uje na GitHub zajedno sa kodom.
- Korisnik odlučuje kada se stavka adresira.
- Kad se stavka reši, prebaci u CHANGELOG ili obriši.
