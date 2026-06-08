# KulaWireless — TODO

## Poznati problemi (za kasnije)

### Pinterest layout — nije savršen

- **Trenutno stanje**: CSS Grid + `grid-auto-flow: dense` na desktopu (≥900px). Kartice idu u 2 kolone, kraća ide pored duže.
- **Problem (prijavio korisnik 8.6.2026)**: "Nije baš kao Pinterest."
- **Šta tačno ne valja — TODO za korisnika da precizira**:
  - [ ] Razmak između kolona prevelik/premalen?
  - [ ] Redosled čitanja (dense menja source order vizuelno)?
  - [ ] Kartice previše različitih veličina (neujednačeno)?
  - [ ] Nešto drugo?
- **Moguća poboljšanja** (kad korisnik bude hteo):
  - Masonry.js ponovo — u pravom Chrome-u možda radi (bagovalo u test browseru)
  - CSS columns sa pažljivijim `break-inside: avoid` (prethodno imalo preklapanja)
  - JavaScript grid library (Brick.js, Gridstack)

### Drag kategorija na mobilnom — ne radi

- **Trenutno stanje**: Sortable.js sa `forceFallback: true` na `#categoriesContainer`. Radi na desktopu, **ne radi na mobilnom**.
- **Problem (prijavio korisnik 8.6.2026)**: "Kategorije se ne mogu pomicati na mobilnim uređajima."
- **Mogući uzroci**:
  1. `delayOnTouchOnly: true` sa delay 50ms — premalo za kategorije (razlikuje se od long-press za linkove)
  2. Native HTML5 drag-and-drop ne radi na touch uređajima
  3. Sortable.js fallback (mouse emulation) ima problema sa višestrukim touch eventima
  4. `attachAllMobileHandlers()` per-link touch listeneri (sa `preventDefault()`) mogu da blokiraju i Sortable na parent
- **Moguća poboljšanja** (kad korisnik bude hteo):
  - Koristiti Sortable bez `forceFallback: true` (probati native drag-and-drop na touch)
  - Povećati delay na touch (`delay: 200`, `delayOnTouchOnly: true`)
  - Koristiti drugu biblioteku (npr. `jquery-ui-sortable`, `dragula`)
  - Implementirati custom touch drag sa `touchstart/touchmove/touchend`

---

## Napomene

- Ovaj fajl se commit-uje na GitHub zajedno sa kodom.
- Korisnik odlučuje kada se stavka adresira.
- Kad se stavka reši, prebaci u CHANGELOG ili obriši.
