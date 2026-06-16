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

/* ===== CC-AR-RTL : gated by [data-cc-dir="rtl"] on <html>; floating toggle injected in index.js ===== */
[data-cc-dir="rtl"] [class*="messagesContainer_" i] p,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] li,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] ul,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] ol,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] blockquote,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] h1,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] h2,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] h3,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] h4,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] h5,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] h6,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] table,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] thead,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] tbody,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] tr,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] th,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] td{
  direction:rtl !important;
  text-align:start !important;
}
[data-cc-dir="rtl"] [class*="messagesContainer_" i] table{
  margin-left:auto !important;
  margin-right:0 !important;
}
[data-cc-dir="rtl"] [class*="messagesContainer_" i] pre,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] pre *,
[data-cc-dir="rtl"] [class*="messagesContainer_" i] code{
  direction:ltr !important;
  text-align:left !important;
  unicode-bidi:normal !important;
}
[data-cc-dir="rtl"] [class*="messagesContainer_" i] pre:has(> code:not([class*="language-"])),
[data-cc-dir="rtl"] [class*="messagesContainer_" i] pre:has(> code:not([class*="language-"])) > code{
  direction:rtl !important;
  text-align:start !important;
  unicode-bidi:plaintext !important;
}
[data-cc-dir="rtl"] [class*="questionsContainer_" i],
[data-cc-dir="rtl"] [class*="questionBlock_" i],
[data-cc-dir="rtl"] [class*="questionItem_" i],
[data-cc-dir="rtl"] [class*="questionHeader_" i],
[data-cc-dir="rtl"] [class*="questionText_" i],
[data-cc-dir="rtl"] [class*="optionsContainer_" i],
[data-cc-dir="rtl"] [class*="option_" i],
[data-cc-dir="rtl"] [class*="optionContent_" i],
[data-cc-dir="rtl"] [class*="optionLabel_" i],
[data-cc-dir="rtl"] [class*="optionDescription_" i],
[data-cc-dir="rtl"] [class*="answerText_" i],
[data-cc-dir="rtl"] [class*="scopeOption_" i],
[data-cc-dir="rtl"] [class*="scopeOptionLabel_" i],
[data-cc-dir="rtl"] [class*="scopeOptionDescription_" i]{
  direction:rtl !important;
  text-align:start !important;
}
/* ===== /CC-AR-RTL ===== */
EOF

# Floating RTL/LTR toggle button appended to webview/index.js
read -r -d '' BTN_BLOCK <<'EOF' || true
;(function(){try{
var K="cc-ar-dir",H=document.documentElement;
var get=function(){try{return localStorage.getItem(K)}catch(e){return null}};
var set=function(v){try{localStorage.setItem(K,v)}catch(e){}};
var cur=function(){return H.getAttribute("data-cc-dir")==="ltr"?"ltr":"rtl"};
var s=get();H.setAttribute("data-cc-dir",s==="ltr"?"ltr":"rtl");
var mk=function(){
 if(!document.body){return setTimeout(mk,300)}
 if(document.getElementById("cc-ar-toggle"))return;
 var b=document.createElement("button");b.id="cc-ar-toggle";b.type="button";
 b.style.cssText="position:fixed;bottom:10px;left:10px;z-index:2147483647;font:11px/1.3 system-ui,sans-serif;padding:4px 9px;border-radius:6px;border:1px solid rgba(127,127,127,.4);background:var(--vscode-button-secondaryBackground,#3a3d41);color:var(--vscode-button-secondaryForeground,#fff);cursor:pointer;opacity:.55;direction:ltr";
 var rnd=function(){b.textContent=cur()==="rtl"?"RTL ⇆":"LTR ⇆";b.title="Toggle Arabic RTL / LTR"};
 b.onmouseenter=function(){b.style.opacity="1"};b.onmouseleave=function(){b.style.opacity=".55"};
 b.onclick=function(){var n=cur()==="rtl"?"ltr":"rtl";H.setAttribute("data-cc-dir",n);set(n);rnd()};
 rnd();document.body.appendChild(b);
};
mk();if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",mk);
}catch(e){}})();
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
      # Floating RTL/LTR toggle button (the gated CSS only applies when it sets data-cc-dir="rtl")
      if ! grep -qF 'cc-ar-toggle' "$jswv"; then
        [ -f "$jswv.bak-arabic" ] || cp "$jswv" "$jswv.bak-arabic"
        printf '%s\n' "$BTN_BLOCK" >> "$jswv"
        echo "PATCHED (toggle button): $(basename "$d")"; patched_any=1
      else
        echo "ALREADY PATCHED (toggle button): $(basename "$d")"
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
