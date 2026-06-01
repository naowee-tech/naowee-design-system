#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# bump.sh — Release helper del Naowee Design System
# ───────────────────────────────────────────────────────────────
# Sincroniza la versión en UN solo comando, para que el pill del
# playground y el CHANGELOG nunca se desincronicen (como pasó con
# v1.4.0 vs 1.8.0).
#
# Toca, de golpe:
#   1. El pill <small>vX.Y.Z</small> en playground.html
#   2. Inserta el scaffold de la entrada en CHANGELOG.md (fecha de hoy)
#   3. (opcional) deja el commit chore(release) hecho
#
# Uso:
#   ./bump.sh <version> ["resumen corto"]
#   ./bump.sh 1.10.0 "Nuevo componente Tooltip"
#   ./bump.sh 1.10.0 "..." --commit     # además commitea
#   ./bump.sh 1.10.0 --dry-run          # muestra qué haría, sin tocar nada
#   ./bump.sh --help
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

# ── Colores (no-op si no es TTY) ──
if [ -t 1 ]; then
  B=$'\033[1m'; DIM=$'\033[2m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; C=$'\033[36m'; X=$'\033[0m'
else
  B=''; DIM=''; G=''; Y=''; R=''; C=''; X=''
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYGROUND="$ROOT/playground.html"
CHANGELOG="$ROOT/CHANGELOG.md"

usage() {
  cat <<EOF
${B}bump.sh${X} — release helper del Naowee Design System

${B}Uso:${X}
  ./bump.sh <version> ["resumen corto"] [flags]

${B}Ejemplos:${X}
  ./bump.sh 1.10.0 "Nuevo componente Tooltip"
  ./bump.sh 1.10.0 "Fix focus ring en inputs" --commit
  ./bump.sh 1.10.0 --dry-run

${B}Flags:${X}
  --commit    Después de editar, crea el commit chore(release): vX.Y.Z
  --dry-run   Muestra qué cambiaría sin escribir nada
  --help      Esta ayuda

${B}Qué hace:${X}
  1. Actualiza el pill <small>vX.Y.Z</small> en playground.html
  2. Inserta la entrada [X.Y.Z] — <hoy> al tope del CHANGELOG.md
  3. (con --commit) deja el commit de release listo

La versión debe ser SemVer (X.Y.Z) y mayor a la actual.
EOF
}

# ── Parse args ──
VERSION=""; SUMMARY=""; DO_COMMIT=0; DRY=0
for arg in "$@"; do
  case "$arg" in
    --help|-h) usage; exit 0 ;;
    --commit)  DO_COMMIT=1 ;;
    --dry-run) DRY=1 ;;
    -*) echo "${R}✗ Flag desconocido: $arg${X}"; echo "   Probá ./bump.sh --help"; exit 1 ;;
    *)
      if [ -z "$VERSION" ]; then VERSION="$arg"
      elif [ -z "$SUMMARY" ]; then SUMMARY="$arg"
      fi ;;
  esac
done

[ -z "$VERSION" ] && { usage; exit 1; }

# ── Validar SemVer ──
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "${R}✗ Versión inválida: '$VERSION'${X}"
  echo "   Debe ser SemVer: X.Y.Z (ej: 1.10.0)"
  exit 1
fi

# ── Sanity: archivos existen ──
[ -f "$PLAYGROUND" ] || { echo "${R}✗ No encuentro playground.html en $ROOT${X}"; exit 1; }
[ -f "$CHANGELOG" ]  || { echo "${R}✗ No encuentro CHANGELOG.md en $ROOT${X}"; exit 1; }

# ── Versión actual (del pill) ──
CURRENT="$(perl -ne 'if (/<small>v([0-9]+\.[0-9]+\.[0-9]+)<\/small>/) { print $1; exit }' "$PLAYGROUND" || true)"
[ -z "$CURRENT" ] && CURRENT="0.0.0"

# ── Validar que sea mayor (usa sort -V) ──
if [ "$VERSION" = "$CURRENT" ]; then
  echo "${R}✗ La versión $VERSION es igual a la actual.${X}"; exit 1
fi
HIGHEST="$(printf '%s\n%s\n' "$CURRENT" "$VERSION" | sort -V | tail -1)"
if [ "$HIGHEST" != "$VERSION" ]; then
  echo "${Y}⚠ La versión $VERSION es MENOR que la actual ($CURRENT).${X}"
  printf "   ¿Continuar igual? [y/N] "
  read -r ans
  [[ "$ans" =~ ^[yY]$ ]] || { echo "   Cancelado."; exit 1; }
fi

TODAY="$(date +%F)"
[ -z "$SUMMARY" ] && SUMMARY="_describe el cambio aquí_"

echo ""
echo "${B}Naowee DS — release${X}"
echo "  ${DIM}actual:${X}  v$CURRENT"
echo "  ${DIM}nueva:${X}   ${G}v$VERSION${X}  ${DIM}($TODAY)${X}"
echo "  ${DIM}resumen:${X} $SUMMARY"
[ "$DRY" = "1" ] && echo "  ${Y}(dry-run — no se escribe nada)${X}"
echo ""

# ── Bloque nuevo del CHANGELOG ──
ENTRY_FILE="$(mktemp)"
cat > "$ENTRY_FILE" <<EOF
## [$VERSION] — $TODAY

### Added
- $SUMMARY

---

EOF

if [ "$DRY" = "1" ]; then
  echo "${C}→ playground.html${X}: <small>v$CURRENT</small> → <small>v$VERSION</small>"
  echo "${C}→ CHANGELOG.md${X}: insertaría al tope:"
  sed 's/^/    /' "$ENTRY_FILE"
  rm -f "$ENTRY_FILE"
  echo "${DIM}(sin cambios escritos)${X}"
  exit 0
fi

# ── 1. Pill en playground.html ──
perl -i -pe "s{<small>v[0-9]+\.[0-9]+\.[0-9]+</small>}{<small>v$VERSION</small>}" "$PLAYGROUND"
echo "${G}✓${X} playground.html — pill → v$VERSION"

# ── 2. Entrada en CHANGELOG.md (antes del primer '## [') ──
awk -v f="$ENTRY_FILE" '
  !done && /^## \[/ {
    while ((getline line < f) > 0) print line
    close(f); done=1
  }
  { print }
' "$CHANGELOG" > "$CHANGELOG.tmp" && mv "$CHANGELOG.tmp" "$CHANGELOG"
rm -f "$ENTRY_FILE"
echo "${G}✓${X} CHANGELOG.md — entrada [$VERSION] insertada"

# ── 3. Commit opcional ──
if [ "$DO_COMMIT" = "1" ]; then
  git -C "$ROOT" add playground.html CHANGELOG.md
  git -C "$ROOT" commit -m "chore(release): v$VERSION — $SUMMARY"
  echo "${G}✓${X} commit creado: chore(release): v$VERSION"
  echo ""
  echo "${DIM}Pusheá con:${X} git -C \"$ROOT\" push"
else
  echo ""
  echo "${B}Siguiente paso${X} — revisá el CHANGELOG (completá la entrada si hace falta) y commiteá:"
  echo "  ${DIM}git add playground.html CHANGELOG.md${X}"
  echo "  ${DIM}git commit -m \"chore(release): v$VERSION — $SUMMARY\"${X}"
  echo "  ${DIM}git push${X}"
fi
