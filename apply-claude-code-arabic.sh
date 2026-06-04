#!/usr/bin/env bash
#
# claude-code-arabic (macOS / Linux)
# Enable Arabic voice dictation + RTL Arabic output in the Claude Code IDE extension
# (Windsurf / VS Code / Cursor). Idempotent; safe to re-run. Run again after each
# extension update (updates overwrite the patched files).
#
# Voice dictation also needs, in your editor settings.json:
#     "accessibility.voice.speechLanguage": "arabic"
#
# Revert a build: copy each "<file>.bak-arabic" back over its file.
#
# DISCLAIMER: modifies a third-party, proprietary extension on your own machine;
# redistributes none of its code. Use at your own risk. MIT-licensed (see LICENSE).
#
set -euo pipefail

# --- Editors to scan (missing ones are skipped) ---
ROOTS=(
  "$HOME/.windsurf/extensions"
  "$HOME/.vscode/extensions"
  "$HOME/.vscode-insiders/extensions"
  "$HOME/.cursor/extensions"
)

# --- English keyterms to bias dictation while speaking Arabic (EDIT FREELY) ---
# Comma-separated, no quotes. Replace with the terms you actually say.
KEYTERMS='API,JSON,HTML,CSS,TypeScript,JavaScript,Python,commit,push,pull,merge,branch,endpoint,frontend,backend,database,localhost,async,await'

# Build the JS keyterm fragment: ,"API","JSON",...
kt_fragment=""
IFS=',' read -ra _kts <<< "$KEYTERMS"
for t in "${_kts[@]}"; do
  t="${t//\"/}"
  kt_fragment="${kt_fragment},\"${t}\""
done

# CSS block appended to webview/index.css
read -r -d '' CSS_BLOCK <<'EOF' || true

/* ===== CC-AR-RTL : RTL for prose/lists/tables; code LTR (except untagged blocks); table right-aligned ===== */
[class*="messagesContainer_" i] p,
[class*="messagesContainer_" i] li,
[class*="messagesContainer_" i] ul,
[class*="messagesContainer_" i] ol,
[class*="messagesContainer_" i] blockquote,
[class*="messagesContainer_" i] h1,
[class*="messagesContainer_" i] h2,
[class*="messagesContainer_" i] h3,
[class*="messagesContainer_" i] h4,
[class*="messagesContainer_" i] h5,
[class*="messagesContainer_" i] h6,
[class*="messagesContainer_" i] table,
[class*="messagesContainer_" i] thead,
[class*="messagesContainer_" i] tbody,
[class*="messagesContainer_" i] tr,
[class*="messagesContainer_" i] th,
[class*="messagesContainer_" i] td{
  direction:rtl !important;
  text-align:start !important;
}
[class*="messagesContainer_" i] table{
  margin-left:auto !important;
  margin-right:0 !important;
}
[class*="messagesContainer_" i] pre,
[class*="messagesContainer_" i] pre *,
[class*="messagesContainer_" i] code{
  direction:ltr !important;
  text-align:left !important;
  unicode-bidi:normal !important;
}
[class*="messagesContainer_" i] pre:has(> code:not([class*="language-"])),
[class*="messagesContainer_" i] pre:has(> code:not([class*="language-"])) > code{
  direction:rtl !important;
  text-align:start !important;
  unicode-bidi:plaintext !important;
}
[class*="questionsContainer_" i],
[class*="questionBlock_" i],
[class*="questionItem_" i],
[class*="questionHeader_" i],
[class*="questionText_" i],
[class*="optionsContainer_" i],
[class*="option_" i],
[class*="optionContent_" i],
[class*="optionLabel_" i],
[class*="optionDescription_" i],
[class*="answerText_" i],
[class*="scopeOption_" i],
[class*="scopeOptionLabel_" i],
[class*="scopeOptionDescription_" i]{
  direction:rtl !important;
  text-align:start !important;
}
/* ===== /CC-AR-RTL ===== */
EOF

patched_any=0

for root in "${ROOTS[@]}"; do
  [ -d "$root" ] || continue
  for d in "$root"/anthropic.claude-code-*; do
    [ -d "$d" ] || continue
    ext="$d/extension.js"
    [ -f "$ext" ] || continue

    # Guard: recognise the build by its language-Set anchor
    if ! grep -qF '"sv","no"])' "$ext" && ! grep -qF '"sv","no","ar"])' "$ext"; then
      echo "SKIP (unrecognised build): $(basename "$d")"
      continue
    fi

    [ -f "$ext.bak-arabic" ] || cp "$ext" "$ext.bak-arabic"

    changed=0
    if grep -qF '"sv","no"])' "$ext"; then
      perl -i -pe 's/"sv","no"\]\)/"sv","no","ar"])/' "$ext"; changed=1
    fi
    if grep -qF 'norwegian:"no",norsk:"no"}' "$ext"; then
      perl -i -pe 's/norwegian:"no",norsk:"no"\}/norwegian:"no",norsk:"no",arabic:"ar"}/' "$ext"; changed=1
    fi
    if grep -qF '"subagent","worktree"]' "$ext"; then
      KT_FRAG="$kt_fragment" perl -i -pe 's/"subagent","worktree"\]/"subagent","worktree"$ENV{KT_FRAG}]/' "$ext"; changed=1
    fi
    if [ "$changed" = 1 ]; then echo "PATCHED (js): $(basename "$d")"; patched_any=1
    else echo "ALREADY PATCHED (js): $(basename "$d")"; fi

    # Webview JS: dir="auto" on rendered markdown
    jswv="$d/webview/index.js"
    if [ -f "$jswv" ]; then
      if grep -qF 'classList.add("rendered-markdown")' "$jswv" && ! grep -qF 'setAttribute("dir","auto")' "$jswv"; then
        [ -f "$jswv.bak-arabic" ] || cp "$jswv" "$jswv.bak-arabic"
        perl -i -pe 's/(\w+)\.element\.classList\.add\("rendered-markdown"\)/$1.element.classList.add("rendered-markdown"),$1.element.setAttribute("dir","auto")/g' "$jswv"
        echo "PATCHED (webview js): $(basename "$d")"; patched_any=1
      else
        echo "ALREADY PATCHED (webview js): $(basename "$d")"
      fi
    fi

    # Webview CSS: RTL block
    css="$d/webview/index.css"
    if [ -f "$css" ]; then
      if ! grep -qF 'CC-AR-RTL' "$css"; then
        [ -f "$css.bak-arabic" ] || cp "$css" "$css.bak-arabic"
        printf '%s\n' "$CSS_BLOCK" >> "$css"
        echo "PATCHED (css): $(basename "$d")"; patched_any=1
      else
        echo "ALREADY PATCHED (css): $(basename "$d")"
      fi
    fi
  done
done

echo ""
[ "$patched_any" = 1 ] || echo "No new patches were needed."
echo "Done. Fully restart your editor (or run 'Developer: Reload Window') to apply."
echo 'Reminder: for Arabic voice, add to settings.json -> "accessibility.voice.speechLanguage": "arabic"'
