# Changelog

Sve bitne izmene projekta start.sokak.app (ex-KulaWireless).

Format baziran na [Keep a Changelog](https://keepachangelog.com/),
projekat koristi [Semantic Versioning](https://semver.org/) (od
open source-ovanja, 2026-Q4).

## [Unreleased]

### Changed
- Open source-ovano pod MIT licencom
- Sanitizovani svi privatni podaci iz git-a (email, SSH kredencijali,
  hosting putanje, analytics ID)
- `api/suggest.php` sada koristi `api/config.php` (van git-a) za
  konfiguraciju
- `scripts/deploy.sh` je generički template sa placeholder-ima
- README prepisan sa punom dokumentacijom za OSS korisnike
- `TODO.md` uklonjen (interne development napomene, vidi git history)

### Removed
- TODO.md (interne napomene sa datumima, tvojim imenom, itd.)
- index.php (specifičan redirect sa stare domene)
- Umami tracking (privacy-first default, opciono kroz README instrukcije)
- `paypal.me/emocentrik` ostaje — korisnici mogu da promene

## [1.0.0] - 2026-Q4 (open source release)

### Features
- Single-page HTML sa 12+ kategorija i 100+ linkova
- Drag & drop sortiranje kategorija (Sortable.js)
- localStorage perzistencija (favoriti, custom linkovi, sortirani
  redosled, sakrivene kategorije, tema)
- Dark / light tema
- Live pretraga linkova
- Mobile-first responsive layout
- Long-press action sheet na mobilnom
- "Predloži link" modal sa PHP backend-om
- "Preporuči sajt" sa Web Share API + clipboard fallback
- ⭐/📌 toolbar dugmad za brzo toggle-ovanje "Moji linkovi" i
  "Custom linkovi" kategorija
- Multi-domain deploy (primarni + legacy URL)
- Auto-bump cache-busting `?v=YYYYMMDDHHMM` na svaki deploy
- Footer sa CC BY-SA 4.0 atribucijom
- Srpski jezik (latinica)
