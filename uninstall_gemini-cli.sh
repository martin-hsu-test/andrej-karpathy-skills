#!/usr/bin/env bash
# Uninstall andrej-karpathy-skills from Gemini CLI.
# Removes both gemini-md block and skill (whichever exist).
# Will NOT touch unrelated content in your GEMINI.md.
#
#   --scope user       (default) Operate on ~/.gemini/
#   --scope workspace            Operate on ./GEMINI.md and workspace skill

set -euo pipefail

SCOPE="user"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope) SCOPE="$2"; shift 2 ;;
    -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "❌ Unknown arg: $1" >&2; exit 1 ;;
  esac
done

case "$SCOPE" in user|workspace) ;;
  *) echo "❌ --scope must be: user | workspace" >&2; exit 1 ;;
esac

if [[ "$SCOPE" == "user" ]]; then
  GEMINI_MD="$HOME/.gemini/GEMINI.md"
else
  GEMINI_MD="$PWD/GEMINI.md"
fi

# Allow override for shell aliases / non-PATH installs.
GEMINI_BIN="${GEMINI_BIN:-gemini}"
HAS_GEMINI=true
if ! command -v "$GEMINI_BIN" >/dev/null 2>&1; then
  HAS_GEMINI=false
fi

echo "🗑  Uninstalling andrej-karpathy-skills (scope: $SCOPE)"
echo

# 1. GEMINI.md block ------------------------------------------------------
echo "▶ [1/2] Removing block from $GEMINI_MD"
if [[ -f "$GEMINI_MD" ]] && grep -qF "<!-- BEGIN karpathy-guidelines -->" "$GEMINI_MD"; then
  awk '
    /^<!-- BEGIN karpathy-guidelines -->$/ {skip=1}
    !skip {print}
    /^<!-- END karpathy-guidelines -->$/ {skip=0; next}
  ' "$GEMINI_MD" > "$GEMINI_MD.tmp" && mv "$GEMINI_MD.tmp" "$GEMINI_MD"
  # Trim trailing blank lines.
  awk 'NF {p=1} p {a[NR]=$0} END {for(i=1;i<=NR;i++) if(a[i]!="" || i<NR) print a[i]}' \
    "$GEMINI_MD" > "$GEMINI_MD.tmp" && mv "$GEMINI_MD.tmp" "$GEMINI_MD"
  echo "   ✓ removed"
else
  echo "   (no block found, skipped)"
fi

# 2. Skill ----------------------------------------------------------------
echo "▶ [2/2] Uninstalling skill: karpathy-guidelines"
if ! $HAS_GEMINI; then
  echo "   (gemini CLI not found, skipped — set GEMINI_BIN if you used skill mode)"
elif "$GEMINI_BIN" skills uninstall karpathy-guidelines --scope "$SCOPE" >/dev/null 2>&1; then
  echo "   ✓ removed"
else
  echo "   (not installed, skipped)"
fi

echo
echo "✅ Done."
