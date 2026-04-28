#!/usr/bin/env bash
# Install andrej-karpathy-skills into Gemini CLI.
#
# Two installation modes (Karpathy's guidelines are "always-on discipline",
# so gemini-md is the default — see README-gemini-cli.zh.md for rationale):
#
#   --mode gemini-md  (default)  Append to GEMINI.md as persistent context.
#   --mode skill                  Install as on-demand skill.
#   --mode both                   Install both.
#
#   --scope user  (default)  Install for current user (~/.gemini/).
#   --scope workspace        Install only into the current working directory.
#
# Re-runnable: GEMINI.md uses a fenced block so re-runs replace cleanly,
# and `gemini skills install` is idempotent.

set -euo pipefail

# --- args ----------------------------------------------------------------
MODE="gemini-md"
SCOPE="user"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --scope) SCOPE="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "❌ Unknown arg: $1" >&2; exit 1 ;;
  esac
done

case "$MODE" in gemini-md|skill|both) ;;
  *) echo "❌ --mode must be: gemini-md | skill | both" >&2; exit 1 ;;
esac
case "$SCOPE" in user|workspace) ;;
  *) echo "❌ --scope must be: user | workspace" >&2; exit 1 ;;
esac

# --- paths ---------------------------------------------------------------
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$REPO_DIR/skills/karpathy-guidelines"
SOURCE_MD="$REPO_DIR/CLAUDE.md"   # same content, reused for GEMINI.md

if [[ "$SCOPE" == "user" ]]; then
  GEMINI_MD="$HOME/.gemini/GEMINI.md"
else
  GEMINI_MD="$PWD/GEMINI.md"
fi

# Override with GEMINI_BIN=/path/to/gemini if `gemini` is a shell alias.
GEMINI_BIN="${GEMINI_BIN:-gemini}"

echo "📦 Installing andrej-karpathy-skills"
echo "   mode:  $MODE"
echo "   scope: $SCOPE"
echo

# --- gemini-md mode ------------------------------------------------------
install_gemini_md() {
  local begin="<!-- BEGIN karpathy-guidelines -->"
  local end="<!-- END karpathy-guidelines -->"

  mkdir -p "$(dirname "$GEMINI_MD")"
  touch "$GEMINI_MD"

  # Strip any existing block, then append fresh.
  if grep -qF "$begin" "$GEMINI_MD"; then
    echo "▶ Updating existing block in $GEMINI_MD"
    # Use awk to delete everything between markers (inclusive).
    awk -v b="$begin" -v e="$end" '
      $0 == b {skip=1}
      !skip {print}
      $0 == e {skip=0; next}
    ' "$GEMINI_MD" > "$GEMINI_MD.tmp" && mv "$GEMINI_MD.tmp" "$GEMINI_MD"
  else
    echo "▶ Appending block to $GEMINI_MD"
  fi

  {
    # Ensure separation from prior content.
    [[ -s "$GEMINI_MD" ]] && echo ""
    echo "$begin"
    # Rewrite the "# CLAUDE.md" title to a tool-neutral one so Gemini
    # doesn't see "CLAUDE.md" inside its own context.
    sed '1s|^# CLAUDE.md$|# Behavioral Guidelines (Karpathy)|' "$SOURCE_MD"
    echo "$end"
  } >> "$GEMINI_MD"

  echo "   ✓ $GEMINI_MD"
}

# --- skill mode ----------------------------------------------------------
install_skill() {
  echo "▶ Installing skill: karpathy-guidelines (scope: $SCOPE)"
  if "$GEMINI_BIN" skills install "$SKILL_DIR" --scope "$SCOPE" --consent >/dev/null 2>&1; then
    echo "   ✓ installed"
  else
    echo "   ❌ FAILED — try: $GEMINI_BIN skills install $SKILL_DIR --scope $SCOPE --consent"
    exit 1
  fi
}

# --- run -----------------------------------------------------------------
[[ "$MODE" == "gemini-md" || "$MODE" == "both" ]] && install_gemini_md
[[ "$MODE" == "skill"     || "$MODE" == "both" ]] && install_skill

echo
echo "✅ Done."
echo
echo "Verify:"
[[ "$MODE" != "skill" ]]     && echo "   grep -c 'karpathy-guidelines' $GEMINI_MD" || true
[[ "$MODE" != "gemini-md" ]] && echo "   gemini skills list | grep karpathy" || true
exit 0
