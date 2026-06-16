# claude-code-arabic

Enable **Arabic voice dictation** and **right-to-left (RTL) Arabic rendering** in the
[Claude Code](https://claude.com/product/claude-code) IDE extension — for **Windsurf,
VS Code, and Cursor**.

Claude Code can already transcribe Arabic speech (via Deepgram Nova-3) and render rich
chat — it just doesn't let you **pick Arabic for dictation**, and it shows Arabic replies
**left-to-right**. This is a small, reversible patch that turns both on, and adds a
one-click **RTL ⇄ LTR toggle** right inside the chat box.

> العربية في الأسفل ⬇️ — [اقفز للشرح العربي](#بالعربية)

---

## What it does

| # | File | Patch |
|---|------|-------|
| 1 | `extension.js` | Add `ar` to the voice-dictation language list |
| 2 | `extension.js` | Add `arabic` → `ar` to the language name map |
| 3 | `extension.js` | Add English tech terms to the dictation keyterm list (so English words are transcribed correctly mid-Arabic) |
| 4 | `webview/index.js` | Set `dir="auto"` on rendered markdown |
| 5 | `webview/index.js` | Inject a floating **RTL ⇆ LTR toggle button** |
| 6 | `webview/index.css` | RTL for chat **prose, lists, tables**, and the question/permission widgets; code blocks stay LTR; tables aligned right |

The RTL rules are **gated** behind a `data-cc-dir="rtl"` attribute that the toggle button sets, so you can switch Arabic display on/off live.

All patches are **idempotent** (re-running skips already-patched builds) and each modified
file gets a pristine `*.bak-arabic` backup beside it.

## Requirements

- Claude Code extension installed in Windsurf, VS Code, and/or Cursor.
- **Windows:** PowerShell 5.1+ (built in).
- **macOS / Linux:** `bash` + `perl` (both standard).

## Install & run

### Windows
```powershell
# from the repo folder
powershell -ExecutionPolicy Bypass -File .\Apply-ClaudeCodeArabicVoice.ps1
```

### macOS / Linux
```bash
chmod +x apply-claude-code-arabic.sh
./apply-claude-code-arabic.sh
```

Then **fully restart your editor** (or run **Developer: Reload Window**).

## Enable Arabic voice dictation

The patch unlocks Arabic; you still tell the editor which language to dictate in. Add to
your editor **settings.json** (User or Workspace):

```json
"accessibility.voice.speechLanguage": "arabic"
```

This affects **dictation only** — it does not force Claude's text replies to Arabic.

## Switching RTL on/off live

After patching, a small **`RTL ⇆`** button appears **inside the chat box**, just before
the "Edit automatically" control. Click it to toggle Arabic RTL display on/off
**instantly — no reload needed**:

- **`RTL ⇆`** (lit) — Arabic mode on (messages, lists, tables render right-to-left).
- **`LTR ⇆`** (dim) — back to the extension's default left-to-right.

Your choice is remembered (saved in `localStorage`) and the default is RTL. The button is
kept in place by a light 1-second check — it does not run any heavy background observer.

## Run again after every update

Updating the extension overwrites the patched files. Just re-run the script — it
re-applies everything and skips anything already done.

## Reverting

Copy each backup back over its file, e.g.:

```powershell
# Windows (adjust the version folder)
$d = "$env:USERPROFILE\.windsurf\extensions\anthropic.claude-code-<version>-win32-x64"
Copy-Item "$d\extension.js.bak-arabic"        "$d\extension.js" -Force
Copy-Item "$d\webview\index.js.bak-arabic"    "$d\webview\index.js" -Force
Copy-Item "$d\webview\index.css.bak-arabic"   "$d\webview\index.css" -Force
```

## Customizing the keyterms

Open the script and edit the keyterms list near the top — put the English terms you
actually say while dictating in Arabic. They bias the speech model toward those words.

## Limitations

- **Code-switching:** speaking Arabic and English freely in one utterance is **not**
  supported by the speech engine (its multilingual mode does not include Arabic).
  Keyterms (patch 3) help only for a fixed list of known English words.
- **Emoji boxes (tofu):** if emoji show as `□`, your OS emoji font may lack those glyphs;
  that needs an OS update, not a CSS change.
- **Selectors may drift:** the RTL CSS targets the chat container's class. If a future
  extension version renames it, the RTL part may stop applying until updated here.

## Disclaimer & legal

This tool modifies a **third-party, proprietary** extension (© Anthropic PBC, all rights
reserved) **on your own machine**. It **redistributes none of that extension's code** — it
only edits files already installed locally. Use **at your own risk**: it may conflict with
the extension's terms of use, and every extension update reverts it. Not affiliated with or
endorsed by Anthropic.

## License

MIT — see [LICENSE](LICENSE).

---

## بالعربية

أداة صغيرة وقابلة للتراجع تُفعّل **الإملاء الصوتي العربي** و**عرض النصوص العربية من اليمين
لليسار (RTL)** في إضافة **Claude Code** داخل **Windsurf / VS Code / Cursor**.

يستطيع Claude Code أصلًا تحويل الكلام العربي إلى نص (عبر Deepgram Nova-3) وعرض محادثة غنيّة،
لكنه **لا يتيح اختيار العربية للإملاء**، ويعرض الردود العربية **من اليسار لليمين**. هذا السكربت
يفعّل الأمرين، ويضيف **زر تبديل RTL ⇄ LTR بنقرة واحدة داخل صندوق المحادثة**.

### ماذا يفعل؟
1. يضيف `ar` لقائمة لغات الإملاء (`extension.js`).
2. يضيف `arabic` → `ar` لخريطة أسماء اللغات.
3. يضيف مصطلحات إنجليزية تقنية لقائمة keyterms (لتُكتب الكلمات الإنجليزية صحيحة وأنت تتكلم عربي).
4. يضبط `dir="auto"` على عناصر الماركداون (`webview/index.js`).
5. يحقن **زر تبديل RTL ⇆ LTR داخل صندوق المحادثة** (`webview/index.js`).
6. يجعل النصوص والقوائم والجداول وودجت الأسئلة RTL، مع إبقاء الكود LTR ومحاذاة الجداول لليمين (`webview/index.css`).

قواعد RTL **مشروطة** بسمة `data-cc-dir="rtl"` التي يضبطها الزر، فيمكنك تشغيل/إطفاء العرض العربي حيًّا.

كل الترقيعات **idempotent** (إعادة التشغيل آمنة)، ولكل ملف نسخة احتياطية `*.bak-arabic`.

### التشغيل
- **ويندوز:** `powershell -ExecutionPolicy Bypass -File .\Apply-ClaudeCodeArabicVoice.ps1`
- **ماك/لينكس:** `chmod +x apply-claude-code-arabic.sh && ./apply-claude-code-arabic.sh`

ثم **أعد تشغيل المحرّر بالكامل** (أو نفّذ **Developer: Reload Window**).

### تفعيل الصوت العربي
أضف إلى **settings.json** في المحرّر:
```json
"accessibility.voice.speechLanguage": "arabic"
```
(يؤثّر على الإملاء فقط، ولا يُجبر ردود Claude على العربية.)

### التبديل بين RTL و LTR حيًّا
بعد الترقيع يظهر زر صغير **`RTL ⇆`** **داخل صندوق المحادثة**، قبل زر "Edit automatically" مباشرة.
اضغطه للتبديل **فورًا بلا إعادة تشغيل**:
- **`RTL ⇆`** (مضيء) — الوضع العربي مفعّل (يمين لليسار).
- **`LTR ⇆`** (باهت) — العودة للوضع الافتراضي (يسار لليمين).

يُحفظ اختيارك (في `localStorage`) والافتراضي RTL. يبقى الزر في مكانه عبر فحص خفيف كل ثانية، بلا أي مراقب ثقيل.

### بعد كل تحديث
التحديث يمسح الترقيع — أعد تشغيل السكربت فقط.

### قيود مهمة
- **الخلط بين العربية والإنجليزية** في جملة واحدة **غير مدعوم** من محرّك الكلام (الوضع متعدّد
  اللغات لا يشمل العربية). الـ keyterms تساعد فقط لقائمة كلمات محدّدة.
- **مربّعات الإيموجي**: إن ظهرت `□` فالخط في نظامك ينقصه الرمز — يلزم تحديث النظام لا CSS.

### إخلاء مسؤولية
يعدّل هذا السكربت إضافة **مملوكة لطرف ثالث (Anthropic، جميع الحقوق محفوظة)** على **جهازك أنت**،
ولا يُعيد توزيع أي من كودها. استخدامك **على مسؤوليتك**؛ قد يخالف شروط الإضافة، ويُلغى مع كل تحديث.
هذه الأداة غير تابعة لـ Anthropic ولا معتمدة منها.
