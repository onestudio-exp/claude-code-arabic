<#
.SYNOPSIS
    Enable Arabic voice dictation + right-to-left (RTL) Arabic output in the
    Claude Code IDE extension (Windsurf / VS Code / Cursor) on Windows.

.DESCRIPTION
    The Claude Code extension ships a hard-coded language allowlist for its voice
    dictation (Deepgram Nova-3 backend). Arabic ("ar") is excluded even though the
    backend supports Arabic + its dialects. Its chat webview also has no RTL handling
    and no emoji-capable font fallback. This script applies small, reversible patches
    to the LOCALLY-INSTALLED extension files. Every extension update overwrites those
    files, so re-run this script after each update.

    Patches (all idempotent — already-patched builds are skipped):
      1. extension.js   - add "ar" to the dictation language Set (QJ).
      2. extension.js   - add arabic:"ar" to the language name->code map (DB0).
      3. extension.js   - extend the dictation keyterm list with English tech terms
                          (Deepgram "keyterm prompting") so English words are
                          transcribed correctly while you speak Arabic. NOTE: true
                          Arabic+English code-switching in one breath is NOT supported
                          by the engine; keyterms are the only mitigation.
      4. webview/index.js  - set dir="auto" on rendered markdown elements.
      5. webview/index.css - RTL for chat prose, lists and tables; code blocks stay
                          LTR (except a bare ``` block whose content is Arabic);
                          tables are pushed to the right.

    A pristine backup ("<file>.bak-arabic") is kept next to every patched file.

.NOTES
    Voice dictation also requires telling the editor which language to dictate in.
    Add this to your editor settings.json (User or Workspace):
        "accessibility.voice.speechLanguage": "arabic"

    After running: fully restart the editor, or run "Developer: Reload Window".
    To revert a build: copy each "<file>.bak-arabic" back over its file.
    Compatible with Windows PowerShell 5.1 and PowerShell 7+.

    DISCLAIMER: This modifies a third-party, proprietary extension on your own
    machine. It redistributes none of that extension's code. Use at your own risk;
    it may conflict with the extension's terms and will be undone by updates.
    MIT-licensed. See README.md and LICENSE.
#>

$ErrorActionPreference = 'Stop'

# --- Editors to scan (all are optional; missing ones are skipped) ---
$extRoots = @(
    "$env:USERPROFILE\.windsurf\extensions",
    "$env:USERPROFILE\.vscode\extensions",
    "$env:USERPROFILE\.vscode-insiders\extensions",
    "$env:USERPROFILE\.cursor\extensions"
)

# --- English keyterms to bias dictation while speaking Arabic (EDIT FREELY) ---
# These are just sensible defaults; replace with the terms you actually say.
$keyterms = @(
    'API','JSON','HTML','CSS','TypeScript','JavaScript','Python',
    'commit','push','pull','merge','branch','endpoint',
    'frontend','backend','database','localhost','async','await'
)

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$patchedAny = $false

foreach ($root in $extRoots) {
    if (-not (Test-Path $root)) { continue }

    $dirs = Get-ChildItem -Path $root -Directory -Filter 'anthropic.claude-code-*' -ErrorAction SilentlyContinue
    foreach ($d in $dirs) {
        $ext = Join-Path $d.FullName 'extension.js'
        if (-not (Test-Path $ext)) { continue }

        $content = [System.IO.File]::ReadAllText($ext, $utf8NoBom)

        # Guard: recognise the build by its language-Set anchor
        if ($content -notmatch '"sv","no"\]\)' -and $content -notmatch '"sv","no","ar"\]\)') {
            Write-Host "SKIP (unrecognised build): $($d.Name)" -ForegroundColor Yellow
            continue
        }

        # Pristine backup, once only
        $bak = "$ext.bak-arabic"
        if (-not (Test-Path $bak)) { Copy-Item $ext $bak }

        $changed = $false

        # Patch 1: add "ar" to the dictation language Set
        if ($content -match '"sv","no"\]\)') {
            $content = $content -replace '"sv","no"\]\)', '"sv","no","ar"])'
            $changed = $true
        }

        # Patch 2: add arabic name to the language name->code map
        if ($content -match 'norwegian:"no",norsk:"no"\}') {
            $content = $content -replace 'norwegian:"no",norsk:"no"\}', 'norwegian:"no",norsk:"no",arabic:"ar"}'
            $changed = $true
        }

        # Patch 3: extend the keyterm list (only when still in unpatched form)
        if ($content -match '"subagent","worktree"\]') {
            $kt = ($keyterms | ForEach-Object { '"' + ($_ -replace '"', '') + '"' }) -join ','
            $content = $content -replace '"subagent","worktree"\]', ('"subagent","worktree",' + $kt + ']')
            $changed = $true
        }

        if ($changed) {
            [System.IO.File]::WriteAllText($ext, $content, $utf8NoBom)
            Write-Host "PATCHED (js): $($d.Name)" -ForegroundColor Green
            $patchedAny = $true
        } else {
            Write-Host "ALREADY PATCHED (js): $($d.Name)" -ForegroundColor Cyan
        }

        # --- Webview JS: set dir="auto" on rendered markdown (content-accurate RTL/LTR) ---
        $jsWv = Join-Path $d.FullName 'webview\index.js'
        if (Test-Path $jsWv) {
            $jsText = [System.IO.File]::ReadAllText($jsWv, $utf8NoBom)
            if ($jsText -match 'classList\.add\("rendered-markdown"\)' -and $jsText -notmatch 'setAttribute\("dir","auto"\)') {
                $jsBak = "$jsWv.bak-arabic"
                if (-not (Test-Path $jsBak)) { Copy-Item $jsWv $jsBak }
                $jsText = $jsText -replace '(\w+)\.element\.classList\.add\("rendered-markdown"\)', '$1.element.classList.add("rendered-markdown"),$1.element.setAttribute("dir","auto")'
                [System.IO.File]::WriteAllText($jsWv, $jsText, $utf8NoBom)
                Write-Host "PATCHED (webview js): $($d.Name)" -ForegroundColor Green
                $patchedAny = $true
            } else {
                Write-Host "ALREADY PATCHED (webview js): $($d.Name)" -ForegroundColor Cyan
            }
        }

        # --- Webview CSS: RTL for chat prose/lists/tables (code stays LTR) ---
        $css = Join-Path $d.FullName 'webview\index.css'
        if (Test-Path $css) {
            $cssText = [System.IO.File]::ReadAllText($css, $utf8NoBom)
            if ($cssText -notmatch 'CC-AR-RTL') {
                $cssBak = "$css.bak-arabic"
                if (-not (Test-Path $cssBak)) { Copy-Item $css $cssBak }
                $cssBlock = @'

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
'@
                [System.IO.File]::WriteAllText($css, ($cssText + $cssBlock), $utf8NoBom)
                Write-Host "PATCHED (css): $($d.Name)" -ForegroundColor Green
                $patchedAny = $true
            } else {
                Write-Host "ALREADY PATCHED (css): $($d.Name)" -ForegroundColor Cyan
            }
        }
    }
}

Write-Host ""
if (-not $patchedAny) {
    Write-Host "No new patches were needed." -ForegroundColor DarkGray
}
Write-Host "Done. Fully restart your editor (or run 'Developer: Reload Window') to apply." -ForegroundColor White
Write-Host "Reminder: for Arabic voice, add to settings.json -> `"accessibility.voice.speechLanguage`": `"arabic`"" -ForegroundColor DarkGray
