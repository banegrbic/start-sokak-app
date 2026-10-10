# start.sokak.app

> Personalizovana start stranica sa linkovima, pretragom, AI alatima,
> medijima, društvenim mrežama i alatima. Jedna strana, sve što ti treba
> na internetu.

**Live demo:** https://start.sokak.app/

🌐 **Jezici / Languages:** [🇷🇸 Srpski](README.md) · [🇬🇧 English](README.en.md)

Brza, responzivna, dark/light tema, bez naloga, bez server-side praćenja
po defaultu. Sva korisnička stanja (favoriti, custom linkovi, sortirani
redosled, sakrivene kategorije) čuvaju se u `localStorage` — privatno,
na uređaju korisnika.

---

## ✨ Features

- **📰 Preko 100 linkova** u 12+ kategorija (mediji, portali, pretraga,
  AI, društvene mreže, alati, zabava, multimedija, domaći servisi, ...)
- **⭐ Favoriti** — prevuci link u "Moji linkovi" kategoriju. dugi pritisak
  na mobilnom otvara action sheet.
- **➕ Custom linkovi** — dodaj svoje linkove. dugme "Dodaj link" u
  hamburger meniju.
- **🌓 Dark / light tema** — automatski pamti izbor.
- **🔍 Live pretraga** — filter po nazivu ili URL-u.
- **👁 Sakrij kategorije** — svaka kategorija ima 👁 dugme, ili koristi
  ⭐/📌 dugmad u toolbaru za brzo toggle-ovanje "Moji linkovi" / "Custom".
- **📱 Responzivan** — radi na desktopu, tabletu, mobilnom. Long-press
  podrška za touch uređaje.
- **🔀 Drag & drop** — menjaj redosled kategorija (desktop) ili koristi
  custom link formu.
- **🍺 Donacija** — opciono PayPal dugme u hamburger meniju (možeš lako
  zameniti sa svojim linkom ili obrisati).
- **💡 Suggest link** — korisnici mogu da predlože link. Server-side
  PHP šalje email administratoru (vidi "API setup" dole).
- **🔗 Preporuči sajt** — Web Share API na mobilnom, copy-to-clipboard
  na desktopu.
- **⚖️ Privacy-first** — NEMA analytics po defaultu. Nema kolačića. Nema
  server-side praćenja. Opciono možeš dodati analytics (Umami, Plausible,
  Google Analytics) — vidi "Analytics" sekciju.
- **♿ Accessibility** — keyboard navigacija, ARIA labele, kontrast boja
  respektuje korisničke sistemske preference.

---

## 📸 Screenshot

_(dodaj screenshot tvog deploya ovde — vidi `docs/screenshots/` za primere)_

![start.sokak.app desktop dark theme](docs/screenshots/desktop-dark.png)
![start.sokak.app mobile](docs/screenshots/mobile.png)

---

## 🚀 Quick start

### Opcija 1: Koristi kao statičan sajt (bez API-ja)

1. Kloniraj repo:
   ```bash
   git clone https://github.com/banegrbic/start-sokak-app.git
   cd start-sokak-app
   ```

2. Otvori `index.html` u browseru — radi!
   ```bash
   # ili lokalni server:
   python3 -m http.server 8000
   # otvori http://localhost:8000
   ```

3. Prilagodi:
   - Izmeni `<a>` tagove u `index.html` da dodaješ/uklanjaš linkove
   - Izmeni emoji ikone i naslove kategorija
   - Prilagodi boje u `responsive.css` (CSS varijable na vrhu fajla)

4. Deploy:
   - **GitHub Pages**, **Netlify**, **Cloudflare Pages**, **Vercel** — samo push.
   - **cPanel / shared hosting** — vidi "Deployment" sekciju dole.

### Opcija 2: Pun setup sa API endpointom (za "Predloži link" dugme)

1. Kloniraj kao gore
2. Na serveru, kreiraj `api/config.php` iz template-a:
   ```bash
   cp api/config.example.php api/config.php
   # Edituj api/config.php sa svojim email-om i SMTP podacima
   ```
3. PHP 7.4+ je potreban (koristi `json_encode`, `filter_var`, `mail()`).

---

## 📂 Project structure

```
.
├── index.html              # Glavni fajl — sav markup + inline JS
├── responsive.css          # Svi stilovi (dark/light tema, responsive)
├── index.php               # (opciono) redirect sa stare domene — vidi dole
├── api/
│   ├── suggest.php         # Server-side handler za "Predloži link"
│   └── config.example.php  # Template za config.php (VAN git-a)
├── scripts/
│   ├── deploy.sh           # Generički deploy template
│   └── bump-version.sh     # Cache-busting helper
├── assets/
│   └── favicon.svg         # Favicon (SVG, transparent pozadina)
├── favicon-{16,32,64}.png  # Favicon u raznim veličinama
├── apple-touch-icon-...    # iOS home screen ikona
├── LICENSE                 # MIT licenca
├── README.md               # Ovaj fajl
└── .gitignore              # SSH secrets, config.php, backup-ovi
```

**Napomena:** Originalni projekat je imao fajlove `index.php` i `TODO.md`
sa privatnim development napomenama (stara domena, stari URL-ovi, itd.).
Ti fajlovi su uklonjeni iz ovog open source repo-a — git history zadržava
originalne podatke za referencu, ali trenutni kod je čist.

---

## ⚙️ Prilagođavanje

### Dodavanje nove kategorije

U `index.html`, kopiraj postojeći `<section class="category">` blok i
prilagodi:

```html
<section class="category" id="category-moja-nova" data-category-name="Moja nova">
  <header class="category-header">
    <button type="button" class="drag-handle" aria-label="Prevuci kategoriju">⋮⋮</button>
    <h2><span class="category-icon">🆕</span> Moja nova <span class="count" data-count></span></h2>
    <button type="button" class="visibility-toggle" aria-label="Sakrij kategoriju" data-visibility-toggle>👁</button>
  </header>
  <div class="links">
    <a href="https://example.com/" draggable="true" data-href="https://example.com/" data-name="Example">Example</a>
  </div>
</section>
```

Važno:
- `id="category-..."` mora biti jedinstven (slug verzija imena)
- `data-category-name` se koristi kao fallback u localStorage
- Svaki `<a>` MORA imati `href`, `data-href`, i `data-name` (isti string
  za data-name i display tekst)

### Dodavanje novog linka u postojeću kategoriju

Nađi kategoriju u `index.html` (pretraga po `data-category-name="..."`)
i dodaj `<a>` unutar `<div class="links">` bloka:

```html
<a href="https://novi-link.com/" draggable="true" data-href="https://novi-link.com/" data-name="Novi Link">Novi Link</a>
```

### Menjanje tema

CSS varijable na vrhu `responsive.css` (u `:root` bloku):

```css
:root {
  --primary-bg: #1a1a1a;     /* Glavna pozadina */
  --secondary-bg: #2a2a2a;   /* Sekundarna (kartice, modal) */
  --text-color: #e0e0e0;     /* Glavni tekst */
  --text-muted: #888;        /* Sekundarni tekst */
  --link-color: #4dabf7;     /* Linkovi i akcenti */
  --border-color: #333;      /* Ivice */
  /* ... */
}
```

Za light temu, koristi `@media (prefers-color-scheme: light)` ili JS
toggle (trenutno korisnik bira ručno preko dugmeta).

### Zamenjivanje PayPal linka

U `index.html` nađi `paypal.me/emocentrik` (2 mesta) i zameni sa svojim
linkom. Ili obriši celu 🍺 dugmad ako ne želiš donation opciju.

---

## 🔌 API setup ("Predloži link" dugme)

Ako želiš da dugme "Predloži link" radi i šalje ti email sa predlozima,
moraš konfigurisati `api/suggest.php`.

### 1. Kreiraj `api/config.php` (van git-a)

```bash
cp api/config.example.php api/config.php
```

Edituj `api/config.php` sa svojim vrednostima:

```php
$TO_EMAIL    = 'tvoj-email@example.com';   // Gde stižu predlozi
$FROM_EMAIL  = 'noreply@tv-domen.com';     // Pošiljalac (mora postojati na domenu)
$FROM_NAME   = 'tvoj-sajt';
$SUBJECT     = '[tvoj-sajt] Novi predlog linka';
```

### 2. Testiraj lokalno

```bash
# PHP built-in server sa routerom za /api/
php -S localhost:8000

# Otvori http://localhost:8000 — probaj dugme "Predloži link"
```

### 3. Na serveru, postavi executable bit

```bash
chmod 755 api/suggest.php
```

### 4. (cPanel) Osiguraj da `mail()` radi

Ako koristiš cPanel, `mail()` obično radi ako imaš email nalog na domenu.
Ako ne radi, kontaktiraj hosting podršku ili koristi PHPMailer sa
SMTP autentikacijom.

### Alternativni backend (bez PHP-a)

Ako deploy-uješ na statičan hosting (GitHub Pages, Netlify, Cloudflare
Pages), `api/suggest.php` neće raditi. Opcije:

1. **Onemogući dugme** — obriši HTML za "Predloži link" u hamburger meniju
2. **Formspree** (https://formspree.io) — zameni `api/suggest.php` logiku
   sa Formspree POST-om (vidi njihov docs)
3. **Netlify Forms** (ako koristiš Netlify) — dodaj `data-netlify="true"`
   atribut na formu
4. **Cloudflare Workers** — napravi serverless funkciju koja šalje email

---

## 📊 Analytics (opciono)

Projekat po defaultu **NE šalje nikakve analytics podatke**. Ako želiš
da pratiš posećenost, dodaj svoj tracking snippet **pre `</body>`** u
`index.html`:

### Umami (preporučeno, privacy-friendly)

```html
<script defer src="https://cloud.umami.is/script.js" data-website-id="TVOJ-WEBSITE-ID"></script>
```

### Plausible

```html
<script defer data-domain="tvoj-domen.com" src="https://plausible.io/js/script.js"></script>
```

### Google Analytics

```html
<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

⚠️ **Pažnja**: Google Analytics prati korisnike bez njihovog pristanka
(u suprotnosti sa GDPR-om u EU). Ako tvoj sajt posećuju EU korisnici,
razmisli o cookie consent baneru ili koristi privacy-friendly alternative
(Umami, Plausible, Fathom).

---

## 🚀 Deployment

### GitHub Pages (najlakše)

1. Push na GitHub
2. Settings → Pages → Source: `master` branch, root
3. Tvoj sajt je na `https://<username>.github.io/start-sokak-app/`

**Limitacija**: `api/suggest.php` neće raditi (GitHub Pages ne podržava
PHP). Vidi "Alternativni backend" gore.

### Netlify / Vercel / Cloudflare Pages

1. Push na GitHub
2. Poveži repo u Netlify/Vercel/Cloudflare dashboard-u
3. Build command: nema (statičan sajt)
4. Publish directory: root

**Netlify posebno**: ima Forms podršku, možeš zameniti
`api/suggest.php` sa `data-netlify="true"` formom.

### cPanel / shared hosting

`scripts/deploy.sh` je generički template — radi sa bilo kojim SSH
dostupnim hostingom.

**Setup (jednom):**

1. Napravi SSH ključ za deploy:
   ```bash
   mkdir -p secrets
   ssh-keygen -t ed25519 -f secrets/deploy-key -N ""
   chmod 600 secrets/deploy-key
   ```

2. Dodaj javni ključ na serveru (`~/.ssh/authorized_keys`).

3. Edituj `scripts/deploy.sh` — postavi `SSH_USER`, `SSH_HOST`,
   `REMOTE_DIR_PRIMARY`, `LIVE_URL_PRIMARY` na tvoje vrednosti.

4. Na serveru, kreiraj `~/public_html/api/` i upload `config.php`.

**Svaki deploy:**
```bash
./scripts/deploy.sh "Opis izmene"
```

Skripta automatski:
- bumpa cache-busting verziju u `index.html`
- commit-uje i push-uje na GitHub
- SCP-uje fajlove na server
- curl-uje live URL da potvrdi novu verziju

### Drugi statični hosting (S3, Firebase, Surge.sh, itd.)

Projekat je 100% statičan (osim opcionog PHP-a). Radi sa bilo čim što
služi HTML/CSS/JS fajlove.

---

## 🤝 Contributing

Pull requests su dobrodošli! Za veće izmene:

1. Otvori issue prvo da diskutujemo šta želiš da promeniš
2. Fork-uj repo
3. Kreiraj branch (`git checkout -b feature/nova-funkcionalnost`)
4. Commit-uj (`git commit -m 'feat: dodaj X'`)
5. Push-uj (`git push origin feature/nova-funkcionalnost`)
6. Otvori Pull Request

**Code style:**
- Vanilla JS (bez TypeScript, bez bundlera)
- 2-space indent
- CSS klase: kebab-case (npr. `.category-header`)
- JS funkcije: camelCase
- Inline JS u `<script>` tagovima (nema eksternih JS fajlova)

**Pre commit-a, testiraj:**
- [ ] Otvori `index.html` u browseru — nema JS grešaka u konzoli
- [ ] Testiraj mobilni layout (Chrome DevTools → device emulation)
- [ ] Probaj dugme "Dodaj link", "Predloži link", theme toggle
- [ ] Ako si menjao CSS — bump `?v=` u `index.html` linku
- [ ] Proveri da nisi slučajno commit-ovao `api/config.php`

---

## 📜 License

Ovaj projekat je licenciran pod **MIT licencom** — vidi [LICENSE](LICENSE)
fajl za detalje.

Kratko: možeš da koristiš, menjaš, distribuiraš, koristiš komercijalno —
samo zadrži copyright notice.

---

## 🙏 Credits

- **Sortable.js** (https://github.com/SortableJS/Sortable) — drag & drop
  funkcionalnost, MIT licenca
- **Inter font** (https://rsms.me/inter/) — tipografija, SIL OFL licenca
- **CC BY-SA 4.0** — sadržaj linkova (kategorije, opisi) je licenciran
  pod CC BY-SA 4.0 (vidljivo u footer-u sajta)

Svi linkovi ka eksternim sajtovima pripadaju svojim vlasnicima. Ovaj
projekat nije povezan sa sajtovima na koje linkuje.

---

## 📞 Kontakt

- GitHub Issues: za bagove i feature request-ove
- Email: vidi `api/config.php` (ili tvoj deploy)

---

## 🗺️ Roadmap

Vidi [CHANGELOG.md](CHANGELOG.md) za istoriju verzija i buduće radove.
