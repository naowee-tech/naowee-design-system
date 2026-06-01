# Changelog

Todos los cambios notables del Design System de Naowee.

Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/). Versiones siguen [SemVer](https://semver.org/lang/es/).

---

## [1.9.0] — 2026-06-01

### Added — Set de iconos oficial desde Figma (142 iconos)
Extracción completa del archivo Figma **"02 - Iconography [NT]"** vía REST API, en su tamaño canónico (xsmall / 24px). Reemplaza la librería aproximada anterior en la sección **Icons** del playground por el set real de diseño.

- **`naowee-icons-data.js`** (nuevo) — define `window.NAOWEE_FIGMA_ICONS` con los 142 iconos normalizados: fill-based outlined paths, `currentColor`, `viewBox 0 0 24 24`, decimales redondeados a 2. Auto-generado, regenerable con el pipeline de extracción.
- **9 categorías**: UI (18), Feedback (4), Control & Action (41), Payments & Finance (21), Shipping (13), People (6), Comms (9), Navigation (17), Others (13).
- **Botón "Descargar pack SVG"** en la sección Icons — empaqueta los 142 SVGs standalone organizados por categoría en subcarpetas + `README.txt` con instrucciones para importar a [icomoon.io](https://icomoon.io). Usa JSZip (CDN, lazy).
- Click en cualquier icono copia su nombre en kebab-case (ej: `chevron-right`, `qr-code`).

> El objeto `NAOWEE_ICONS` legacy se mantiene intacto — lo consumen 44 renders de componentes del playground.

---

## [1.8.0] — 2026-04-29

### Added — Wizard Form Recipe
Receta unificada para wizards/modals con validación, extraída del flujo "Crear nuevo evento" de `naowee-test-sidebar-shell` (que a su vez se inspiró en `naowee-test-incentivos/programa-wizard`). Permite que cualquier producto reutilice el mismo pattern visual y de UX.

- **`.naowee-stepper--pulse`** — modifier que aplica un ring naranja pulsante (2s loop) al `__step--active .__number`. Llama atención al paso en curso.
  ```html
  <ol class="naowee-stepper naowee-stepper--pulse"> ... </ol>
  ```

- **`.naowee-stepper--distributed`** — modifier que estira steps + connectors a ancho completo (`flex: 1 1 0` por step, `flex: 1 1 auto` en connectors). El último step colapsa a su ancho natural. Útil cuando el stepper vive en un header/modal con ancho fijo y queremos distribución pareja sin huecos al final.
  ```html
  <ol class="naowee-stepper naowee-stepper--pulse naowee-stepper--distributed"> ... </ol>
  ```

- **`.naowee-shake`** — utility que aplica wiggle horizontal (450ms, cubic-bezier de anticipación) a cualquier elemento. Pensado para campos `--error` cuando una validación bloquea el avance del wizard. Para reiniciar la animación en re-trigger:
  ```js
  wrap.classList.remove('naowee-shake');
  void wrap.offsetWidth;        // forzar reflow
  wrap.classList.add('naowee-shake');
  setTimeout(() => wrap.classList.remove('naowee-shake'), 500);
  ```

- **`.naowee-datepicker--compact`** — variante del calendario reducida a 266px (vs 412px default), con celdas 32×32 y tipografía 12px. Diseñada para popups anclados a inputs en grids estrechos (ej: dos fechas en columna 50/50 dentro de un modal).

- **`.naowee-datepicker--popover`** + **`.naowee-datepicker--open`** — wrapper para mostrar el calendario como popup flotante con elevación (`box-shadow: 0 12px 32px rgba(40,40,52,.14)`), `position: fixed`, `z-index: 10000`. El consumer posiciona vía JS (`getBoundingClientRect` del trigger). Fade+slide visible cuando se le agrega `--open`.

### Pattern: Validación lazy con shake + auto-scroll
Recomendación documentada para integradores. El handler de "Siguiente" debe:
1. Validar el step actual y construir un objeto `errors`
2. Para cada campo inválido, agregar `naowee-textfield--error` o `naowee-dropdown--error` al wrapper + insertar un `<div class="naowee-helper naowee-helper--negative">` con badge SVG y texto
3. Hacer scroll suave del modal body al primer inválido (`body.scrollTo({ top: ..., behavior: 'smooth' })`)
4. Después de 260ms, aplicar `.naowee-shake` a todos los wrappers inválidos (re-trigger después del scroll para que la animación sea visible)

Al editar/seleccionar un campo válido, limpieza quirúrgica (sin re-render):
- Remover clase `--error` del wrapper
- Remover el `.naowee-helper--negative` del DOM

### Pattern: Range integrity con auto-clear
Cuando dos datepickers forman rango "from/to":
- "to" usa "from" como `minDate` — días anteriores se renderizan con `.naowee-datepicker__day--disabled`
- Si el usuario cambia "from" a una fecha posterior al "to" actual, "to" se limpia automáticamente con flash visual rojo (2.8s) + helper temporal de aviso
- Convención de markup: `data-range="from|to"` + `data-range-name="<rango compartido>"` para que el JS de los pickers se enlace por nombre

### Fixed
- **`naowee-modal--fixed-header` dismiss padding asimétrico** — el header tenía `padding: 16px 32px`, dejando el botón `__dismiss` a 16px del top y 32px del right (visualmente desbalanceado). Ahora es `padding: 16px` (simétrico) y el `__title-group` tiene `padding-left: 16px` para conservar el indent de 32px del título respecto al body. Resultado: el dismiss queda equidistante del top y del right edge sin afectar la posición del título.

### Backwards compatibility
- ✅ Todas las clases nuevas son opt-in (modifiers/utilities). Sin cambios en `.naowee-stepper` base, `.naowee-datepicker` base, ni `.naowee-modal` base.
- ⚠️ El padding del `__header` cambia en `--fixed-header` — productos que dependieran de los 32px laterales del header (no del body) verán el título 16px más cerca del edge si no usan `__title-group`. Revisar en consumers existentes.

---

## [1.7.0] — 2026-04-30

### Changed
- **`naowee-btn--loud` hover comportamiento** — reemplaza `bg-darker` por elevation naranja
  - Antes: `:hover` cambiaba `background: fill-loud-idle → fill-loud-hover` (más oscuro), generaba "flash" visual
  - Ahora: `:hover` y `:focus-visible` mantienen el bg y agregan `box-shadow: var(--naowee-shadow-loud-md)` (sombra naranja)
  - Tamaño `--large` → sombra más prominente (`--naowee-shadow-loud-lg`)
  - `:active` → bg mantiene + sombra reducida (`--naowee-shadow-loud-xs`) para press feel
  - Patrón validado en `naowee-test-incentivos` (botón "Nuevo programa" en `incentivo-03-programas.html`)

### Added
- **Tokens de elevation loud** (acento naranja) — disponibles globalmente:
  - `--naowee-shadow-loud-xs` (2px / 14% opacity)
  - `--naowee-shadow-loud-sm` (4px / 18%)
  - `--naowee-shadow-loud-md` (6px / 22%) — usado en btn--loud hover
  - `--naowee-shadow-loud-lg` (10px / 32%) — usado en btn--loud--large hover
  - `--naowee-shadow-loud-xl` (16px / 38%) — para CTAs destacadas (modals, hero)

- **Tokens de brand glow** (naranja primario):
  - `--naowee-shadow-brand-md` (6px / 24% rgba(255,117,0)) — variante intermedia
  - `--naowee-shadow-brand-lg` (12px / 30%) — para hovers de cards/tiles

### Why
Patrón "el bg se mantiene + sombra naranja" se sintió más profesional y consistente que "bg cambia a más oscuro" en producción (validado en incentivos). Migrar al DS unifica el comportamiento en todos los productos que consuman el componente.

### Backwards compatibility
- ✅ Solo cambia el hover. Idle, disabled, loading, focus por keyboard se mantienen.
- ✅ Productos que dependían del `:hover` del DS reciben automáticamente la mejora al actualizar a v1.7.0.

---

## [1.6.0] — 2026-04-29

### Added
- **`naowee-page-header`** — patrón uniforme para títulos de página
  - `__title` (24px / 700 / -.3px tracking)
  - `__subtitle` (13px / 400 / text-secondary)
  - Reemplaza implementaciones ad-hoc en CRUD pages (Gestión de usuarios, Eventos, etc.)

- **`naowee-filter-dropdown`** — dropdown compacto para toolbars
  - Distinto al `.naowee-dropdown` de forms: altura `36px`, radius `8px`, sin label/helper
  - Estados: idle / hover / open (accent border + 3px shadow ring)
  - Slots: `__trigger`, `__chev`, `__menu`, `__option`, `__option-check` (con `aria-selected="true"`)
  - Pensado para vivir en `.naowee-table-card__toolbar` u otros toolbars

- **`naowee-empty-state`** — estado vacío genérico
  - `__icon` (48×48 con color text-disabled)
  - `__title` (16px / 700)
  - `__description` (13px / max-width 320px)
  - `__action` slot (típicamente un `naowee-btn--mute` para "Limpiar filtros")
  - Reemplaza implementaciones custom en listas, búsquedas sin resultados, tablas vacías

### Playground
- 3 nuevos componentes con controles toggleables: `pageHeader`, `filterDropdown`, `emptyState`

### Why
Estos 3 componentes quedaban como overrides locales en `naowee-test-sidebar-shell` después de migrar a `naowee-table-card` (v1.5.0). Subirlos al DS elimina la última deuda local del sandbox y los hace reusables en cualquier CRUD page del ecosistema Naowee.

---

## [1.5.0] — 2026-04-29

### Added
- **`naowee-table-card`** — nuevo componente compuesto para CRUD pages (Data Table Card)
  - Container que compone `.naowee-tabs--animated` + toolbar (search + filters + pagination) + tabla + row actions, todo en un solo card cohesivo
  - Validado en producción en `suite-web-v2` (pantalla "Gestión de usuarios") y portado desde el patrón `tablet` de `naowee-test-incentivos`
  - Clases agregadas:
    - `.naowee-table-card` — container con `border-radius: 16px`, `padding: 20px`, flex column con `gap: 18px`
    - `.naowee-table-card__toolbar` — row con search + filters + pagination
    - `.naowee-table-card__toolbar-left` — slot izquierdo (search + filtros)
    - `.naowee-table-card__table-wrap` — wrapper con scrollbar oculto (no reserva gutter)
    - `.naowee-table-card__row-actions` + `__row-actions-menu` + `__row-actions-item` — popover de acciones por fila (3-dots con menu)
    - `.naowee-table-card__row-actions-item--danger` — variante destructiva
  - **`.naowee-table--in-card`** — modifier de la tabla base con thead `bg: #f5f6fa` + border-radius en first/last child + padding más generoso (`16px 18px`)
  - **`.naowee-table__cell-name`** y **`.naowee-table__cell-muted`** — utilities tipográficas de celdas (weight 500 para nombres, secondary para subtexto)
- **Override de `.naowee-pagination--small`** dentro del card:
  - `gap: 12px` entre `__pages` y `__controls` (DS por default deja `0`)
  - Input cuadrado `32×32` (DS default era `48×32` rectangular)
  - Spinners nativos del input number ocultos (Webkit + Firefox)
- **Playground**: nuevo demo `tableCard` con controles para tabs/toolbar/pagination toggleables y switch entre 2 tabs

### Why
Las pantallas tipo "Gestión de usuarios", "Listado de eventos", "Documentación", etc. comparten el mismo patrón: tabs entre tipos de entidad + filtros + tabla paginada + acciones por fila. Este componente lo formaliza como spec del DS y elimina la necesidad de re-implementarlo en cada producto. La spec visual se mantiene en `naowee-tech/naowee-test-sidebar-shell`.

---

## [1.4.0] — 2026-04-22

### Added
- **Code block con syntax highlighting por componente** (estilo Vercel/Linear)
  - Nueva función `highlightHtml(raw)` — wrappea tokens (tag / attr / string / comment / punct) con spans de clase para colorear
  - Nueva función `formatHtml(str)` — indenta el HTML con 2 espacios por nivel basándose en apertura / cierre / self-closing de tags
  - Nueva función `copyCode()` — copia el texto crudo formateado (no el markup coloreado), usa `data-raw` attr del `<pre>`
- **Header del code block estilo macOS**: 3 dots de semáforo + label monospace "HTML" + botón Copy con icon SVG
- **Estados del botón Copy**: verde cuando copiado, con label "Copied" por 1.6s, vuelve a "Copy"
- **Scrollbar custom** en code blocks (8px, `rgba(255,255,255,.12)` con hover más claro)
- **Altura aumentada** del code block: 220px → 340px `max-height`

### Syntax highlight tokens
- `.hl-tag` → `#ff9a4f` (nombres de elementos)
- `.hl-attr` → `#68a9ff` (atributos)
- `.hl-str` → `#a7d49a` (strings en comillas)
- `.hl-punct` → `#71717a` (`<`, `>`, `/`)
- `.hl-com` → `#4b4b58` italic (comentarios HTML)

---

## [1.3.0] — 2026-04-21

### Changed
- **Playground rediseñado con el mismo look & feel Vercel/Linear** de la landing.
  - Shell: body con gradient mesh + grid pattern en fondo, sidebar con `backdrop-blur`, topbar translúcido
  - Sidebar: brand mark con color orange accent, version badge monospace, search con focus glow
  - Nav: group headers estilo `// comment` en JetBrains Mono, items activos con border-left naranja y bg sutil
  - Topbar: título tight `letter-spacing:-.015em`, badge monospace con border y bg translúcido
  - Preview wrap: card blanca flotando con `box-shadow` profunda para contraste con bg dark
  - Controls panel: bg translúcido con backdrop-blur, títulos en monospace
  - Segmented control: estilo dark con selected state sutil
  - Code blocks: estilo macOS window (header con label + Copy button) con syntax dark, JetBrains Mono 12px
  - Foundation grids: semantic items, radius items, type rows, spacing bars, icon cards — todos migrados a tema dark con monospace en metadata
  - Tags (Figma/Custom): estilos translúcidos con borders acorde al bg dark

---

## [1.2.0] — 2026-04-21

### Changed
- **Landing rediseñada con estética Vercel / Linear**: tema oscuro (#08080c), gradient mesh animado con acentos naranjas, noise grid sutil con mask radial, typography tight con `letter-spacing: -.045em`, JetBrains Mono en code blocks y metadata.
- Hero con pill clickeable (v1.2.0 release), gradient text con stop naranja en "Naowee", CTAs primary/ghost con glow shadow.
- Feature cards con cursor-following radial gradient (`--mx`, `--my` tracking via `mousemove`).
- Install section con code block estilo macOS window (dots de semáforo + label + botón Copy con clipboard API).
- Stats row: 4 números grandes (17 componentes · 1 archivo · 229 KB · 0 deps) con gradient text.
- Components grid: 17 items con dot naranja, hover transforma a tono brand.
- Footer minimalista con separadores y monospace version badge.
- Animaciones de entrada (`fadeUp` con stagger) en elementos del hero.

---

## [1.1.0] — 2026-04-21

### Added
- **Landing page** (`index.html`) separada del playground. Hero + features grid + snippet de instalación CDN + grid de componentes clickeable.
- Navegación entre landing y `playground.html` con nav sticky arriba.
- Badge de versión visible en la landing.

### Changed
- `index.html` anterior (el playground) se renombró a `playground.html`. El nuevo `index.html` es una landing pública profesional.
- GitHub Pages ahora sirve la landing en `/` y el playground en `/playground.html`.

---

## [1.0.0] — 2026-04-21

### Added

Primera release oficial del DS como single source of truth. Consolidación de las versiones dispersas en los siguientes repos/worktrees:

- `digitacion-ui-ux-demo/digitacion/design-system.css` (main, versión base)
- `escenarios-ux-ui-demo/shared/design-system.css` (copia con más componentes)
- `Claude-Doug/.claude/worktrees/suspicious-northcutt-3aafc0/design-system.css` (versión con segment pill animado)

#### Componentes incluidos

- **Buttons** — `.naowee-btn` con jerarquías `--loud` (primary), `--quiet` (secondary / ghost), `--mute` (tertiary). Variantes `--on-fill` y `--on-fill-inverse` para contextos sobre color
- **Text fields** — `.naowee-textfield` con estados idle/focus/error/disabled
- **Search box** — `.naowee-searchbox` con variantes `--medium`, `--squared`, `--rounded` + menú de resultados
- **Dropdowns** — multi-select con checkboxes, single-select, color swatches
- **Tabs** — `.naowee-tabs` + `.naowee-tab--selected` con pipe inferior animado
- **Tabs animados** — variante `.naowee-tabs--animated` con sliding indicator que se desliza entre tabs
- **Segmented control** — `.naowee-segment` con nuevo **sliding pill animado** (`__pill`, `--segment-pill-x`, transition 380ms cubic-bezier)
- **Breadcrumb** — con chevron SVG + variante `--back` con flecha
- **Badges** — `.naowee-badge` con variantes de estado
- **Tags** — dismissible con close button
- **Messages** — alerts informativos con 4 variantes semánticas
- **Modal** — con `__dismiss` estándar
- **Floating footer** — logo Naowee + derechos reservados
- **File uploader** — textfield-based con multi-file + variante photo (card-based con dismiss on-hover)
- **Toggle / switch**
- **Checkbox / radio**
- **Shortcuts** — quick action pills

#### Helpers JS

- `dist/tabs.js` — auto-init de `.naowee-tabs--animated`, evento `naowee-tab:change`, respeta `prefers-reduced-motion`

#### Infra

- Playground (`index.html`) servido vía GitHub Pages
- CDN estable vía jsDelivr (`https://cdn.jsdelivr.net/gh/douguizard/naowee-design-system/dist/design-system.css`)
- README con guía de uso, migración y desarrollo

### Migration notes

Repos que actualmente tienen `shared/design-system.css` como copia local:
- `escenarios-ux-ui-demo` — seguirá funcionando; recomendado migrar al CDN en próximo release
- `digitacion-ui-ux-demo` — idem

No hay breaking changes respecto a la copia local más reciente (`escenarios-ux-ui-demo`). El consumo es idéntico: mismo markup, mismas clases.

---
